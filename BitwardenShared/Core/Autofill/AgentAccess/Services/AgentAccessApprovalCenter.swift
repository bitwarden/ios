import BitwardenKit
import Combine
import Foundation

// MARK: - AgentAccessApprovalOutcome

/// How a pending approval request ended.
///
enum AgentAccessApprovalOutcome: Equatable, Sendable {
    /// The user approved the request with a vault item.
    case approved(AgentAccessSdkCredential)

    /// The user denied the request, or it was cancelled.
    case denied

    /// The approval window passed.
    case expired
}

// MARK: - AgentAccessApprovalCenter

/// Holds the pending approval requests and the automatic approval rules. Requests are created on
/// SDK threads, which block until the UI layer answers, the window passes or the request is cancelled.
///
final class AgentAccessApprovalCenter: @unchecked Sendable {
    // MARK: Types

    /// A pending request and the signal used to wake the thread waiting on it.
    private final class Entry {
        let request: AgentAccessApprovalRequest
        let semaphore = DispatchSemaphore(value: 0)
        var outcome: AgentAccessApprovalOutcome?

        init(request: AgentAccessApprovalRequest) {
            self.request = request
        }
    }

    // MARK: Properties

    /// The pending requests, oldest first.
    private var entries: [Entry] = []

    /// Guards all mutable state. Recursive so subscribers can call back in.
    private let lock = NSRecursiveLock()

    /// The subject that publishes the pending requests.
    private let pendingSubject = CurrentValueSubject<[AgentAccessApprovalRequest], Never>([])

    /// The rules that approve identical requests without asking.
    private var rules: [AgentAccessAutoApproveRule] = []

    /// The provider used to get the current time.
    private let timeProvider: TimeProvider

    // MARK: Initialization

    /// Initialize an `AgentAccessApprovalCenter`.
    ///
    /// - Parameter timeProvider: The provider used to get the current time.
    ///
    init(timeProvider: TimeProvider) {
        self.timeProvider = timeProvider
    }

    // MARK: Pending Requests

    /// Publishes the pending requests, oldest first.
    func pendingRequestsPublisher() -> AnyPublisher<[AgentAccessApprovalRequest], Never> {
        pendingSubject.eraseToAnyPublisher()
    }

    /// The pending requests, oldest first.
    func pendingRequests() -> [AgentAccessApprovalRequest] {
        lock.lock()
        defer { lock.unlock() }
        return entries.map(\.request)
    }

    /// Returns the pending request with the ID, if it is still pending.
    func pendingRequest(id: String) -> AgentAccessApprovalRequest? {
        lock.lock()
        defer { lock.unlock() }
        return entries.first { $0.request.id == id }?.request
    }

    /// Publishes the request and blocks until it is answered, cancelled or its window passes.
    /// Must not be called from the main thread or a Swift concurrency thread.
    func requestApproval(_ request: AgentAccessApprovalRequest) -> AgentAccessApprovalOutcome {
        let entry = Entry(request: request)
        lock.lock()
        entries.append(entry)
        publish()
        lock.unlock()

        let remaining = request.expiresAt.timeIntervalSince(timeProvider.presentTime)
        if remaining > 0 {
            _ = entry.semaphore.wait(timeout: .now() + remaining)
        }

        lock.lock()
        defer { lock.unlock() }
        if let outcome = entry.outcome {
            return outcome
        }
        entries.removeAll { $0 === entry }
        publish()
        return .expired
    }

    /// Answers a pending request.
    ///
    /// - Returns: The request that was answered, or `nil` if it is no longer pending or has expired.
    ///
    @discardableResult
    func resolve(id: String, outcome: AgentAccessApprovalOutcome) -> AgentAccessApprovalRequest? {
        lock.lock()
        defer { lock.unlock() }
        guard let index = entries.firstIndex(where: { $0.request.id == id }),
              entries[index].request.expiresAt > timeProvider.presentTime else {
            return nil
        }
        let entry = entries.remove(at: index)
        entry.outcome = outcome
        publish()
        entry.semaphore.signal()
        return entry.request
    }

    /// Denies every pending request, or only those of one connection.
    func denyAll(connectionFingerprint: String? = nil) {
        lock.lock()
        defer { lock.unlock() }
        let matching = entries.filter { entry in
            connectionFingerprint == nil || entry.request.connectionFingerprint == connectionFingerprint
        }
        guard !matching.isEmpty else { return }
        entries.removeAll { entry in matching.contains { $0 === entry } }
        for entry in matching {
            entry.outcome = .denied
            entry.semaphore.signal()
        }
        publish()
    }

    // MARK: Automatic Approval Rules

    /// Adds a rule, replacing any rule for the same connection and query.
    func addRule(
        connectionFingerprint: String,
        connectionName: String,
        query: AgentAccessQuery,
        cipherId: String,
        duration: TimeInterval,
    ) {
        lock.lock()
        defer { lock.unlock() }
        rules.removeAll { $0.connectionFingerprint == connectionFingerprint && $0.query.matchKey == query.matchKey }
        rules.append(AgentAccessAutoApproveRule(
            id: UUID().uuidString,
            connectionFingerprint: connectionFingerprint,
            connectionName: connectionName,
            query: query,
            cipherId: cipherId,
            expiresAt: timeProvider.presentTime.addingTimeInterval(duration),
        ))
    }

    /// The rules that haven't expired.
    func autoApproveRules() -> [AgentAccessAutoApproveRule] {
        lock.lock()
        defer { lock.unlock() }
        pruneRules()
        return rules
    }

    /// Returns the rule that approves the request, if any.
    func matchingRule(connectionFingerprint: String, query: AgentAccessQuery) -> AgentAccessAutoApproveRule? {
        lock.lock()
        defer { lock.unlock() }
        pruneRules()
        return rules.first { $0.connectionFingerprint == connectionFingerprint && $0.query.matchKey == query.matchKey }
    }

    /// Removes a rule.
    func removeRule(id: String) {
        lock.lock()
        defer { lock.unlock() }
        rules.removeAll { $0.id == id }
    }

    /// Removes the rules of one connection, or all rules when no connection is given.
    func removeRules(connectionFingerprint: String? = nil) {
        lock.lock()
        defer { lock.unlock() }
        guard let connectionFingerprint else {
            rules.removeAll()
            return
        }
        rules.removeAll { $0.connectionFingerprint == connectionFingerprint }
    }

    // MARK: Private Methods

    /// Publishes the pending requests. The caller holds the lock.
    private func publish() {
        pendingSubject.send(entries.map(\.request))
    }

    /// Drops the expired rules. The caller holds the lock.
    private func pruneRules() {
        let now = timeProvider.presentTime
        rules.removeAll { $0.expiresAt <= now }
    }
}
