import BitwardenKit
import Foundation

// MARK: - AgentAccessSessionHandler

/// Handles the SDK callbacks of one running client: persistence, approvals, pairing and audit.
///
final class AgentAccessSessionHandler: AgentAccessSdkHandler { // swiftlint:disable:this type_body_length
    // MARK: Types

    /// A rendezvous fingerprint comparison waiting for the user.
    private final class Verification {
        let semaphore = DispatchSemaphore(value: 0)
        var approved = false
    }

    // MARK: Properties

    /// The approval center used to ask the user.
    private let approvalCenter: AgentAccessApprovalCenter

    /// How long the user has to answer a request before it is denied.
    private let approvalTimeout: TimeInterval

    /// Counts requests answered automatically, so their SDK approval event is audited as such.
    private var autoApprovedCounts: [String: Int] = [:]

    /// Counts requests that expired, so their SDK denial event isn't audited twice.
    private var expiredCounts: [String: Int] = [:]

    /// The service used by the application to report non-fatal errors.
    private let errorReporter: ErrorReporter

    /// Guards the counters and verifications.
    private let lock = NSLock()

    /// Called with each pairing event.
    private let onPairingEvent: @Sendable (AgentAccessPairingEvent) -> Void

    /// Called with each status change.
    private let onStatus: @Sendable (AgentAccessConnectionStatus) -> Void

    /// The store used to persist the data of the user.
    private let store: AgentAccessStore

    /// The provider used to get the current time.
    private let timeProvider: TimeProvider

    /// The ID of the user the session belongs to.
    let userId: String

    /// The object used to read vault items.
    private let vaultAccessor: AgentAccessVaultAccessor

    /// The fingerprint comparisons waiting for the user, by ID.
    private var verifications: [String: Verification] = [:]

    // MARK: Initialization

    /// Initialize an `AgentAccessSessionHandler`.
    ///
    /// - Parameters:
    ///   - approvalCenter: The approval center used to ask the user.
    ///   - approvalTimeout: How long the user has to answer a request before it is denied.
    ///   - errorReporter: The service used by the application to report non-fatal errors.
    ///   - onPairingEvent: Called with each pairing event.
    ///   - onStatus: Called with each status change.
    ///   - store: The store used to persist the data of the user.
    ///   - timeProvider: The provider used to get the current time.
    ///   - userId: The ID of the user the session belongs to.
    ///   - vaultAccessor: The object used to read vault items.
    ///
    init(
        approvalCenter: AgentAccessApprovalCenter,
        approvalTimeout: TimeInterval = AgentAccessConstants.approvalTimeout,
        errorReporter: ErrorReporter,
        onPairingEvent: @escaping @Sendable (AgentAccessPairingEvent) -> Void,
        onStatus: @escaping @Sendable (AgentAccessConnectionStatus) -> Void,
        store: AgentAccessStore,
        timeProvider: TimeProvider,
        userId: String,
        vaultAccessor: AgentAccessVaultAccessor,
    ) {
        self.approvalCenter = approvalCenter
        self.approvalTimeout = approvalTimeout
        self.errorReporter = errorReporter
        self.onPairingEvent = onPairingEvent
        self.onStatus = onStatus
        self.store = store
        self.timeProvider = timeProvider
        self.userId = userId
        self.vaultAccessor = vaultAccessor
    }

    // MARK: Methods

    /// Answers a pending rendezvous fingerprint comparison.
    func answerFingerprintVerification(id: String, approved: Bool) {
        lock.lock()
        let verification = verifications.removeValue(forKey: id)
        lock.unlock()
        verification?.approved = approved
        verification?.semaphore.signal()
    }

    /// Writes an audit entry for the user.
    func writeAudit(
        kind: AgentAccessAuditKind,
        connectionFingerprint: String,
        connectionName: String?,
        query: AgentAccessQuery?,
        cipherId: String?,
    ) {
        let entry = AgentAccessAuditEntry(
            id: UUID(),
            date: timeProvider.presentTime,
            kind: kind,
            connectionFingerprint: connectionFingerprint,
            connectionName: connectionName,
            query: query,
            cipherId: cipherId,
        )
        do {
            let store = store
            let userId = userId
            try AgentAccessBlocking.run { try await store.appendAudit(entry, userId: userId) }
        } catch {
            errorReporter.log(error: error)
        }
    }

    // MARK: AgentAccessSdkHandler

    func connection(fingerprint: String) -> AgentAccessStoredConnection? {
        listConnections().first { $0.fingerprint == fingerprint }
    }

    func credential(for query: AgentAccessQuery, remoteFingerprint: String) -> AgentAccessSdkCredential? {
        let name = connection(fingerprint: remoteFingerprint)?.name ?? String(remoteFingerprint.prefix(8))
        let key = counterKey(remoteFingerprint, query)

        let vaultAccessor = vaultAccessor
        let userId = userId
        if let rule = approvalCenter.matchingRule(connectionFingerprint: remoteFingerprint, query: query),
           (try? AgentAccessBlocking.run { await vaultAccessor.isVaultUnlocked(userId: userId) }) == true {
            do {
                let credential = try AgentAccessBlocking.run {
                    try await vaultAccessor.credential(forCipherId: rule.cipherId, userId: userId)
                }
                increment(&autoApprovedCounts, key)
                return credential
            } catch {
                approvalCenter.removeRule(id: rule.id)
            }
        }

        let now = timeProvider.presentTime
        let request = AgentAccessApprovalRequest(
            id: UUID().uuidString,
            userId: userId,
            connectionFingerprint: remoteFingerprint,
            connectionName: name,
            query: query,
            receivedAt: now,
            expiresAt: now.addingTimeInterval(approvalTimeout),
        )
        switch approvalCenter.requestApproval(request) {
        case let .approved(credential):
            return credential
        case .denied:
            return nil
        case .expired:
            increment(&expiredCounts, key)
            writeAudit(
                kind: .credentialExpired,
                connectionFingerprint: remoteFingerprint,
                connectionName: name,
                query: query,
                cipherId: nil,
            )
            return nil
        }
    }

    func handle(event: AgentAccessSdkEvent) {
        switch event {
        case .connecting:
            onStatus(.connecting)
        case .connected,
             .listening,
             .reconnected:
            onStatus(.listening)
        case .disconnected,
             .reconnecting:
            onStatus(.reconnecting)
        case let .error(message, isTerminal):
            guard isTerminal else { return }
            onStatus(.failed(message: message))
            onPairingEvent(.failed(message: message))
        case .other:
            break
        }
    }

    func handle(auditEvent: AgentAccessSdkAuditEvent) {
        let fingerprint = auditEvent.remoteFingerprint
        let storedName = connection(fingerprint: fingerprint)?.name
        let name = auditEvent.remoteName ?? storedName

        var kind = auditEvent.kind
        switch auditEvent.kind {
        case .credentialApproved:
            if let query = auditEvent.query, decrement(&autoApprovedCounts, counterKey(fingerprint, query)) {
                kind = .credentialAutoApproved
            }
        case .credentialDenied:
            if let query = auditEvent.query, decrement(&expiredCounts, counterKey(fingerprint, query)) {
                return
            }
        default:
            break
        }

        writeAudit(
            kind: kind,
            connectionFingerprint: fingerprint,
            connectionName: name,
            query: auditEvent.query,
            cipherId: auditEvent.cipherId,
        )

        switch auditEvent.kind {
        case .connectionEstablished:
            let stored = connection(fingerprint: fingerprint)
            let now = timeProvider.presentTime
            onPairingEvent(.paired(AgentAccessConnection(
                fingerprint: fingerprint,
                name: name,
                pairedAt: stored.map { Date(timeIntervalSince1970: TimeInterval($0.cachedAt)) } ?? now,
                lastConnectedAt: stored.map { Date(timeIntervalSince1970: TimeInterval($0.lastConnectedAt)) } ?? now,
            )))
        case .connectionRejected:
            onPairingEvent(.rejected)
        case .credentialRequested,
             .sessionRefreshed:
            touchConnection(fingerprint: fingerprint)
        default:
            break
        }
    }

    func listConnections() -> [AgentAccessStoredConnection] {
        do {
            let store = store
            let userId = userId
            return try AgentAccessBlocking.run { try await store.userData(userId: userId).connections }
        } catch {
            errorReporter.log(error: error)
            return []
        }
    }

    func loadIdentity() -> Data? {
        do {
            let store = store
            let userId = userId
            return try AgentAccessBlocking.run { try await store.userData(userId: userId).identity }
        } catch {
            errorReporter.log(error: error)
            return nil
        }
    }

    func saveConnection(_ connection: AgentAccessStoredConnection) throws {
        let store = store
        let userId = userId
        try AgentAccessBlocking.run {
            try await store.update(userId: userId) { data in
                data.connections.removeAll { $0.fingerprint == connection.fingerprint }
                data.connections.append(connection)
            }
        }
    }

    func saveIdentity(_ identity: Data) throws {
        let store = store
        let userId = userId
        try AgentAccessBlocking.run {
            try await store.update(userId: userId) { $0.identity = identity }
        }
    }

    func updateConnection(fingerprint: String, lastConnectedAt: UInt64) throws {
        let store = store
        let userId = userId
        try AgentAccessBlocking.run {
            try await store.update(userId: userId) { data in
                guard let index = data.connections.firstIndex(where: { $0.fingerprint == fingerprint }) else {
                    return
                }
                data.connections[index].lastConnectedAt = lastConnectedAt
            }
        }
    }

    func verifyFingerprint(code: String, remoteFingerprint: String?) -> Bool {
        let id = UUID().uuidString
        let verification = Verification()
        lock.lock()
        verifications[id] = verification
        lock.unlock()

        onPairingEvent(.verifyFingerprint(AgentAccessFingerprintVerification(
            id: id,
            code: code,
            remoteFingerprint: remoteFingerprint ?? "",
        )))

        let result = verification.semaphore.wait(timeout: .now() + approvalTimeout)
        if result == .timedOut {
            lock.lock()
            verifications.removeValue(forKey: id)
            lock.unlock()
            return false
        }
        return verification.approved
    }

    // MARK: Private Methods

    /// Records that the connection was just used, for its last used date. The SDK only does this
    /// for the remote side of a connection.
    private func touchConnection(fingerprint: String) {
        do {
            let now = UInt64(timeProvider.presentTime.timeIntervalSince1970)
            try updateConnection(fingerprint: fingerprint, lastConnectedAt: now)
        } catch {
            errorReporter.log(error: error)
        }
    }

    /// The key counting requests of one connection and query.
    private func counterKey(_ fingerprint: String, _ query: AgentAccessQuery) -> String {
        "\(fingerprint)|\(query.matchKey)"
    }

    /// Increments a counter.
    private func increment(_ counts: inout [String: Int], _ key: String) {
        lock.lock()
        defer { lock.unlock() }
        counts[key, default: 0] += 1
    }

    /// Decrements a counter.
    ///
    /// - Returns: `true` if the counter was above zero.
    ///
    private func decrement(_ counts: inout [String: Int], _ key: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        guard let count = counts[key], count > 0 else { return false }
        counts[key] = count - 1
        return true
    }
}

// MARK: - AgentAccessSessionHandler + Sendable

extension AgentAccessSessionHandler: @unchecked Sendable {}
