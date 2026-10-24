// swiftlint:disable file_length

import BitwardenKit
import Combine
import Foundation
import UIKit

// MARK: - DefaultAgentAccessRepository

/// The default implementation of `AgentAccessRepository`.
///
final class DefaultAgentAccessRepository: AgentAccessRepository { // swiftlint:disable:this type_body_length
    // MARK: Properties

    /// The application instance, used to request background time while a pairing is pending.
    private let application: Application?

    /// The approval center holding pending requests and rules.
    private let approvalCenter: AgentAccessApprovalCenter

    /// The task that ends the background grace period when the pairing expires.
    private var backgroundExpiryTask: Task<Void, Never>?

    /// The identifier of the background task requested for a pending pairing.
    private var backgroundTaskId: UIBackgroundTaskIdentifier?

    /// The subscription that ends the background grace period when the pairing completes.
    private var backgroundPairingCancellable: AnyCancellable?

    /// The service used to get server-specified configuration.
    private let configService: ConfigService

    /// The subscriptions that write the debug dump.
    private var debugCancellables: Set<AnyCancellable> = []

    /// Whether the debug auto pairing was already started in this process.
    private var debugDidStartAutoPairing = false

    /// The task that writes the debug dump.
    private var debugDumpTask: Task<Void, Never>?

    /// The environment variables used for debug hooks and the relay URL override.
    private let environment: [String: String]

    /// The service used by the application to report non-fatal errors.
    private let errorReporter: ErrorReporter

    /// The service used by the application for recording temporary debug logs.
    private let flightRecorder: FlightRecorder

    /// The most recent pairing, for the debug dump.
    private var lastPairing: AgentAccessPairing?

    /// The most recent status, for the debug dump.
    private var lastStatus: AgentAccessConnectionStatus = .disabled

    /// Guards the mutable state of the repository.
    private let lock = NSLock()

    /// The service that runs the Agent Access client.
    private let service: AgentAccessService

    /// The service used by the application to manage account state.
    private let stateService: StateService

    /// The store used to persist the data of each user.
    private let store: AgentAccessStore

    /// The provider used to get the current time.
    private let timeProvider: TimeProvider

    /// The object used to read vault items.
    private let vaultAccessor: AgentAccessVaultAccessor

    // MARK: Initialization

    /// Initialize a `DefaultAgentAccessRepository`.
    ///
    /// - Parameters:
    ///   - application: The application instance, used to request background time.
    ///   - approvalCenter: The approval center holding pending requests and rules.
    ///   - configService: The service used to get server-specified configuration.
    ///   - environment: The environment variables used for debug hooks and the relay URL override.
    ///   - errorReporter: The service used by the application to report non-fatal errors.
    ///   - flightRecorder: The service used by the application for recording temporary debug logs.
    ///   - service: The service that runs the Agent Access client.
    ///   - stateService: The service used by the application to manage account state.
    ///   - store: The store used to persist the data of each user.
    ///   - timeProvider: The provider used to get the current time.
    ///   - vaultAccessor: The object used to read vault items.
    ///
    init(
        application: Application?,
        approvalCenter: AgentAccessApprovalCenter,
        configService: ConfigService,
        environment: [String: String] = ProcessInfo.processInfo.environment,
        errorReporter: ErrorReporter,
        flightRecorder: FlightRecorder,
        service: AgentAccessService,
        stateService: StateService,
        store: AgentAccessStore,
        timeProvider: TimeProvider,
        vaultAccessor: AgentAccessVaultAccessor,
    ) {
        self.application = application
        self.approvalCenter = approvalCenter
        self.configService = configService
        self.environment = environment
        self.errorReporter = errorReporter
        self.flightRecorder = flightRecorder
        self.service = service
        self.stateService = stateService
        self.store = store
        self.timeProvider = timeProvider
        self.vaultAccessor = vaultAccessor

        #if DEBUG
        if environment[AgentAccessConstants.debugDumpEnvironmentKey] == "1" {
            startDebugDump()
        }
        #endif
    }

    // MARK: Settings

    func isFeatureEnabled() async -> Bool {
        await configService.getFeatureFlag(.agentAccess)
    }

    func isListeningEnabled() async -> Bool {
        guard await isFeatureEnabled(), let userId = try? await activeUserId() else { return false }
        return await listeningEnabled(userId: userId)
    }

    func setListeningEnabled(_ enabled: Bool) async throws {
        try await requireFeature()
        let userId = try await activeUserId()
        try await store.update(userId: userId) { $0.listeningEnabled = enabled }
        if enabled {
            try await service.start(userId: userId)
        } else {
            await service.unregisterIdentity(userId: userId)
            await service.stop()
        }
        scheduleDebugDump()
    }

    func relayURL() async -> String {
        var stored: String?
        if let userId = try? await activeUserId() {
            stored = try? await store.userData(userId: userId).relayURL
        }
        return AgentAccessRelayURL.resolve(stored: stored, environment: environment)
    }

    func setRelayURL(_ url: String) async throws {
        try await requireFeature()
        guard AgentAccessRelayURL.isValid(url) else { throw AgentAccessError.invalidRelayURL }
        let userId = try await activeUserId()
        try await store.update(userId: userId) { $0.relayURL = url }
        if service.runningUserId == userId {
            await service.stop()
            try await service.start(userId: userId)
        }
    }

    func statusPublisher() -> AnyPublisher<AgentAccessConnectionStatus, Never> {
        service.statusPublisher().receive(on: DispatchQueue.main).eraseToAnyPublisher()
    }

    // MARK: Pairing

    func createPairing(kind: AgentAccessPairingKind, name: String) async throws -> AgentAccessPairing {
        try await requireFeature()
        let userId = try await activeUserId()
        if service.runningUserId != userId {
            try await store.update(userId: userId) { $0.listeningEnabled = true }
            try await service.start(userId: userId)
        }
        let pairing = try await service.createPairing(kind: kind, name: name)
        lock.lock()
        lastPairing = pairing
        lock.unlock()
        scheduleDebugDump()
        return pairing
    }

    func pairingEventsPublisher() -> AnyPublisher<AgentAccessPairingEvent, Never> {
        service.pairingEventsPublisher().receive(on: DispatchQueue.main).eraseToAnyPublisher()
    }

    func answerFingerprintVerification(id: String, approved: Bool) {
        service.answerFingerprintVerification(id: id, approved: approved)
    }

    // MARK: Connections

    func connections() async throws -> [AgentAccessConnection] {
        let userId = try await activeUserId()
        return try await store.userData(userId: userId).connections
            .map { connection in
                AgentAccessConnection(
                    fingerprint: connection.fingerprint,
                    name: connection.name,
                    pairedAt: Date(timeIntervalSince1970: TimeInterval(connection.cachedAt)),
                    lastConnectedAt: Date(timeIntervalSince1970: TimeInterval(connection.lastConnectedAt)),
                )
            }
            .sorted { $0.lastConnectedAt > $1.lastConnectedAt }
    }

    func revokeConnection(fingerprint: String) async throws {
        let userId = try await activeUserId()
        let name = try await store.userData(userId: userId).connections
            .first { $0.fingerprint == fingerprint }?.name
        try await store.update(userId: userId) { data in
            data.connections.removeAll { $0.fingerprint == fingerprint }
        }
        approvalCenter.removeRules(connectionFingerprint: fingerprint)
        approvalCenter.denyAll(connectionFingerprint: fingerprint)
        if service.runningUserId == userId {
            await service.restart()
        }
        try await store.appendAudit(
            AgentAccessAuditEntry(
                id: UUID(),
                date: timeProvider.presentTime,
                kind: .connectionRevoked,
                connectionFingerprint: fingerprint,
                connectionName: name,
                query: nil,
                cipherId: nil,
            ),
            userId: userId,
        )
        scheduleDebugDump()
    }

    // MARK: Approvals

    func pendingRequestsPublisher() -> AnyPublisher<[AgentAccessApprovalRequest], Never> {
        approvalCenter.pendingRequestsPublisher().receive(on: DispatchQueue.main).eraseToAnyPublisher()
    }

    func pendingRequest(id: String) async -> AgentAccessApprovalRequest? {
        approvalCenter.pendingRequest(id: id)
    }

    func candidates(for requestId: String) async throws -> [AgentAccessCandidate] {
        guard let request = approvalCenter.pendingRequest(id: requestId) else {
            throw AgentAccessError.requestNotFound
        }
        return try await vaultAccessor.candidates(for: request.query, userId: request.userId)
    }

    func answer(requestId: String, decision: AgentAccessDecision) async throws {
        guard let request = approvalCenter.pendingRequest(id: requestId) else {
            throw AgentAccessError.requestNotFound
        }
        guard request.expiresAt > timeProvider.presentTime else {
            throw AgentAccessError.requestExpired
        }

        switch decision {
        case .deny:
            guard approvalCenter.resolve(id: requestId, outcome: .denied) != nil else {
                throw AgentAccessError.requestExpired
            }
        case let .approve(cipherId, autoApproveMinutes):
            let credential = try await vaultAccessor.credential(forCipherId: cipherId, userId: request.userId)
            guard approvalCenter.resolve(id: requestId, outcome: .approved(credential)) != nil else {
                throw AgentAccessError.requestExpired
            }
            if let autoApproveMinutes, AgentAccessConstants.autoApproveDurationsMinutes.contains(autoApproveMinutes) {
                approvalCenter.addRule(
                    connectionFingerprint: request.connectionFingerprint,
                    connectionName: request.connectionName,
                    query: request.query,
                    cipherId: cipherId,
                    duration: TimeInterval(autoApproveMinutes * 60),
                )
            }
        }
        scheduleDebugDump()
    }

    func autoApproveRules() async -> [AgentAccessAutoApproveRule] {
        approvalCenter.autoApproveRules()
    }

    func removeAutoApproveRule(id: String) async {
        approvalCenter.removeRule(id: id)
    }

    // MARK: Audit

    func auditLog() async throws -> [AgentAccessAuditEntry] {
        let userId = try await activeUserId()
        return try await Array(store.userData(userId: userId).audit.prefix(AgentAccessConstants.maxAuditEntries))
    }

    func clearAuditLog() async throws {
        let userId = try await activeUserId()
        try await store.update(userId: userId) { $0.audit = [] }
    }

    // MARK: Lifecycle

    func appDidBecomeActive() async {
        endBackgroundGrace(stopClient: false)
        guard await isFeatureEnabled(), let userId = try? await activeUserId() else { return }
        await startIfListening(userId: userId)
        #if DEBUG
        startDebugAutoPairingIfNeeded(userId: userId)
        #endif
    }

    func appDidEnterBackground() async {
        if service.hasPendingPairing {
            beginBackgroundGrace()
        } else {
            await service.stop()
        }
    }

    func activeAccountChanged(userId: String?) async {
        await service.stop()
        guard let userId, await isFeatureEnabled() else { return }
        await startIfListening(userId: userId)
    }

    func notificationTapped(userId: String) async {
        guard await isFeatureEnabled() else { return }
        await startIfListening(userId: userId)
    }

    // MARK: Private Methods

    /// The ID of the active account.
    private func activeUserId() async throws -> String {
        do {
            return try await stateService.getActiveAccountId()
        } catch {
            throw AgentAccessError.noActiveAccount
        }
    }

    /// Whether the user turned on listening.
    private func listeningEnabled(userId: String) async -> Bool {
        await (try? store.userData(userId: userId).listeningEnabled) ?? false
    }

    /// Throws if the feature flag is off.
    private func requireFeature() async throws {
        guard await isFeatureEnabled() else { throw AgentAccessError.featureDisabled }
    }

    /// Starts the client for the user if they turned on listening.
    private func startIfListening(userId: String) async {
        guard await listeningEnabled(userId: userId) else { return }
        do {
            try await service.start(userId: userId)
        } catch let error as AgentAccessError {
            await flightRecorder.log("[AgentAccess] Could not start: \(error)")
        } catch {
            errorReporter.log(error: error)
        }
    }

    // MARK: Private Methods (Background Grace)

    /// Keeps the client alive for the OS background grace period while a pairing is pending.
    private func beginBackgroundGrace() {
        lock.lock()
        defer { lock.unlock() }
        guard backgroundTaskId == nil, backgroundExpiryTask == nil else { return }

        backgroundTaskId = application?.startBackgroundTask(withName: "AgentAccessPairing") { [weak self] in
            self?.endBackgroundGrace(stopClient: true)
        }
        backgroundPairingCancellable = service.pairingEventsPublisher().sink { [weak self] event in
            switch event {
            case .failed,
                 .paired,
                 .rejected:
                self?.endBackgroundGrace(stopClient: true)
            case .verifyFingerprint,
                 .waitingForAgent:
                break
            }
        }
        backgroundExpiryTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(AgentAccessConstants.pskPairingLifetime * 1_000_000_000))
            guard !Task.isCancelled else { return }
            self?.endBackgroundGrace(stopClient: true)
        }
    }

    /// Ends the background grace period.
    ///
    /// - Parameter stopClient: Whether to stop the client when the app is still in the background.
    ///
    private func endBackgroundGrace(stopClient: Bool) {
        lock.lock()
        let taskId = backgroundTaskId
        let hadGrace = taskId != nil || backgroundExpiryTask != nil
        backgroundTaskId = nil
        backgroundExpiryTask?.cancel()
        backgroundExpiryTask = nil
        backgroundPairingCancellable = nil
        lock.unlock()

        if let taskId, taskId != .invalid {
            application?.endBackgroundTask(taskId)
        }
        guard stopClient, hadGrace else { return }
        Task {
            if await application?.applicationState != .active {
                await service.stop()
            }
        }
    }

    // MARK: Private Methods (Debug)

    /// Writes the debug dump soon. Does nothing unless the debug dump is enabled.
    private func scheduleDebugDump() {
        #if DEBUG
        guard environment[AgentAccessConstants.debugDumpEnvironmentKey] == "1" else { return }
        lock.lock()
        debugDumpTask?.cancel()
        debugDumpTask = Task { [weak self] in
            await self?.writeDebugDump()
        }
        lock.unlock()
        #endif
    }

    #if DEBUG
    /// Subscribes to state changes so the dump stays current.
    private func startDebugDump() {
        service.statusPublisher()
            .sink { [weak self] status in
                guard let self else { return }
                lock.lock()
                lastStatus = status
                lock.unlock()
                scheduleDebugDump()
            }
            .store(in: &debugCancellables)
        service.pairingEventsPublisher()
            .sink { [weak self] _ in self?.scheduleDebugDump() }
            .store(in: &debugCancellables)
        approvalCenter.pendingRequestsPublisher()
            .sink { [weak self] _ in self?.scheduleDebugDump() }
            .store(in: &debugCancellables)
    }

    /// Creates a PSK pairing once the vault is unlocked, when the debug environment asks for it.
    private func startDebugAutoPairingIfNeeded(userId: String) {
        guard let name = environment[AgentAccessConstants.debugAutoPskNameEnvironmentKey], !name.isEmpty else {
            return
        }
        lock.lock()
        let alreadyStarted = debugDidStartAutoPairing
        debugDidStartAutoPairing = true
        lock.unlock()
        guard !alreadyStarted else { return }

        Task { [weak self] in
            for _ in 0 ..< 60 {
                guard let self else { return }
                if await listeningEnabled(userId: userId), await vaultAccessor.isVaultUnlocked(userId: userId) {
                    _ = try? await createPairing(kind: .psk, name: name)
                    return
                }
                try? await Task.sleep(nanoseconds: 2_000_000_000)
            }
        }
    }

    /// Writes a snapshot of the state to `Documents/agent-access-debug.json`. Never contains credentials.
    private func writeDebugDump() async {
        let userId = try? await activeUserId()
        var fingerprint: String?
        var connections: [String] = []
        if let userId {
            fingerprint = await service.identityFingerprint(userId: userId)
            let stored = await (try? store.userData(userId: userId).connections) ?? []
            connections = stored.map { String($0.fingerprint.prefix(8)) }
        }

        lock.lock()
        let status = lastStatus
        let pairing = lastPairing
        lock.unlock()

        let statusText = switch status {
        case .disabled: "disabled"
        case .connecting: "connecting"
        case .listening: "listening"
        case .reconnecting: "reconnecting"
        case let .failed(message): "failed: \(message)"
        }
        let pending = approvalCenter.pendingRequests().map { request in
            ["id": request.id, "connectionName": request.connectionName, "query": request.query.displayValue]
        }
        let dump: [String: Any] = [
            "userId": userId ?? NSNull(),
            "identityFingerprint": fingerprint ?? NSNull(),
            "status": statusText,
            "lastPairingToken": pairing?.token ?? NSNull(),
            "lastPairingKind": pairing.map { $0.kind == .psk ? "psk" : "rendezvous" } ?? NSNull(),
            "pendingRequests": pending,
            "connections": connections,
        ]
        guard let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first,
              let data = try? JSONSerialization.data(withJSONObject: dump, options: [.prettyPrinted, .sortedKeys])
        else { return }
        try? data.write(to: directory.appendingPathComponent("agent-access-debug.json"), options: .atomic)
    }
    #endif
}

// MARK: - DefaultAgentAccessRepository + Sendable

extension DefaultAgentAccessRepository: @unchecked Sendable {}
