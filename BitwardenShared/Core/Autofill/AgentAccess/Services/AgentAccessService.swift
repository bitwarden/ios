import BitwardenKit
import Combine
import Foundation
import Networking

// MARK: - AgentAccessService

/// A protocol for a service that runs the Agent Access client for the active account.
///
protocol AgentAccessService: AnyObject { // sourcery: AutoMockable
    /// Whether a pairing token has been created that hasn't been used or expired yet.
    var hasPendingPairing: Bool { get }

    /// The ID of the user the client is running for, or `nil` if the client isn't running.
    var runningUserId: String? { get }

    /// Answers a fingerprint verification raised while pairing.
    ///
    /// - Parameters:
    ///   - id: The ID of the verification.
    ///   - approved: Whether the user confirmed that the fingerprints match.
    ///
    func answerFingerprintVerification(id: String, approved: Bool)

    /// Creates a pairing token or code for a new connection.
    ///
    /// - Parameters:
    ///   - kind: The kind of pairing to create.
    ///   - name: The name of the connection.
    /// - Returns: The pairing to show to the user.
    ///
    func createPairing(kind: AgentAccessPairingKind, name: String) async throws -> AgentAccessPairing

    /// Returns the identity fingerprint stored for the user, if any.
    ///
    /// - Parameter userId: The ID of the user.
    ///
    func identityFingerprint(userId: String) async -> String?

    /// Whether the user's identity has the given fingerprint.
    ///
    /// - Parameters:
    ///   - userId: The ID of the user.
    ///   - fingerprint: The 64 character hex identity fingerprint.
    /// - Returns: `true` if the fingerprint belongs to the user's identity on this device.
    ///
    func ownsIdentity(userId: String, fingerprint: String) async -> Bool

    /// A publisher of pairing progress events.
    ///
    func pairingEventsPublisher() -> AnyPublisher<AgentAccessPairingEvent, Never>

    /// Reconnects the running client so the relay flushes any buffered requests.
    ///
    func restart() async

    /// Starts the client for the user: loads or creates the identity, registers it with the server
    /// and connects to the relay. Does nothing if the client is already running for the user.
    ///
    /// - Parameter userId: The ID of the user to start the client for.
    ///
    func start(userId: String) async throws

    /// A publisher of the connection status.
    ///
    func statusPublisher() -> AnyPublisher<AgentAccessConnectionStatus, Never>

    /// Stops the client and resolves any pending requests as denied.
    ///
    func stop() async

    /// Removes the server registration of the user's stored identity.
    ///
    /// - Parameter userId: The ID of the user.
    ///
    func unregisterIdentity(userId: String) async
}

// MARK: - DefaultAgentAccessService

/// The default implementation of `AgentAccessService`.
///
final class DefaultAgentAccessService: AgentAccessService, @unchecked Sendable {
    // MARK: Types

    /// Carries the result of a serialized operation out of its closure.
    private final class ValueBox<T>: @unchecked Sendable {
        var value: T?
    }

    /// The mutable state of the service.
    private struct State {
        var client: AgentAccessSdkClient?
        var handler: AgentAccessSessionHandler?
        var pendingPairing: AgentAccessPairing?
        var userId: String?
    }

    // MARK: Properties

    /// The service used to register identities with the server.
    private let apiService: AgentAccessAPIService

    /// The center that holds pending approvals and auto-approve rules.
    private let approvalCenter: AgentAccessApprovalCenter

    /// The process environment, used for the relay URL override.
    private let environment: [String: String]

    /// The service used to report errors.
    private let errorReporter: ErrorReporter

    /// The service used to record flight recorder logs.
    private let flightRecorder: FlightRecorder

    /// Guards `state`.
    private let lock = NSLock()

    /// Publishes pairing progress. Replays the latest event to new subscribers.
    private let pairingSubject = CurrentValueSubject<AgentAccessPairingEvent, Never>(.waitingForAgent)

    /// The factory that creates SDK clients.
    private let sdkClientFactory: AgentAccessSdkClientFactory

    /// Serializes start, stop and restart.
    private let serializer = SerialWorker()

    /// The mutable state.
    private var state = State()

    /// Publishes the connection status.
    private let statusSubject = CurrentValueSubject<AgentAccessConnectionStatus, Never>(.disabled)

    /// The store of per-user Agent Access data.
    private let store: AgentAccessStore

    /// The provider of the current time.
    private let timeProvider: TimeProvider

    /// Reads vault items for approvals.
    private let vaultAccessor: AgentAccessVaultAccessor

    // MARK: Computed Properties

    var hasPendingPairing: Bool {
        guard let pairing = currentState().pendingPairing else { return false }
        return pairing.expiresAt > timeProvider.presentTime
    }

    var runningUserId: String? {
        currentState().userId
    }

    // MARK: Initialization

    /// Initialize a `DefaultAgentAccessService`.
    ///
    /// - Parameters:
    ///   - apiService: The service used to register identities with the server.
    ///   - approvalCenter: The center that holds pending approvals and auto-approve rules.
    ///   - environment: The process environment, used for the relay URL override.
    ///   - errorReporter: The service used to report errors.
    ///   - flightRecorder: The service used to record flight recorder logs.
    ///   - sdkClientFactory: The factory that creates SDK clients.
    ///   - store: The store of per-user Agent Access data.
    ///   - timeProvider: The provider of the current time.
    ///   - vaultAccessor: Reads vault items for approvals.
    ///
    init(
        apiService: AgentAccessAPIService,
        approvalCenter: AgentAccessApprovalCenter,
        environment: [String: String] = ProcessInfo.processInfo.environment,
        errorReporter: ErrorReporter,
        flightRecorder: FlightRecorder,
        sdkClientFactory: AgentAccessSdkClientFactory,
        store: AgentAccessStore,
        timeProvider: TimeProvider,
        vaultAccessor: AgentAccessVaultAccessor,
    ) {
        self.apiService = apiService
        self.approvalCenter = approvalCenter
        self.environment = environment
        self.errorReporter = errorReporter
        self.flightRecorder = flightRecorder
        self.sdkClientFactory = sdkClientFactory
        self.store = store
        self.timeProvider = timeProvider
        self.vaultAccessor = vaultAccessor
    }

    // MARK: Methods

    func answerFingerprintVerification(id: String, approved: Bool) {
        currentState().handler?.answerFingerprintVerification(id: id, approved: approved)
    }

    func createPairing(kind: AgentAccessPairingKind, name: String) async throws -> AgentAccessPairing {
        try await serialized { [self] in
            guard let client = currentState().client else { throw AgentAccessError.notListening }
            let now = timeProvider.presentTime
            let token: String
            let lifetime: TimeInterval
            switch kind {
            case .psk:
                token = try await client.getPskToken(name: name, reusable: false)
                lifetime = AgentAccessConstants.pskPairingLifetime
            case .rendezvous:
                token = try await client.getRendezvousToken(name: name)
                lifetime = AgentAccessConstants.rendezvousPairingLifetime
            }
            let pairing = AgentAccessPairing(
                kind: kind,
                token: token,
                name: name,
                createdAt: now,
                expiresAt: now.addingTimeInterval(lifetime),
            )
            updateState { $0.pendingPairing = pairing }
            pairingSubject.send(.waitingForAgent)
            return pairing
        }
    }

    func identityFingerprint(userId: String) async -> String? {
        try? await store.userData(userId: userId).identityFingerprint
    }

    func ownsIdentity(userId: String, fingerprint: String) async -> Bool {
        guard let stored = await identityFingerprint(userId: userId) else { return false }
        return stored == fingerprint
    }

    func pairingEventsPublisher() -> AnyPublisher<AgentAccessPairingEvent, Never> {
        pairingSubject.eraseToAnyPublisher()
    }

    func restart() async {
        _ = try? await serialized { [self] in
            guard let client = currentState().client else { return }
            await client.close()
            try await client.connect()
        }
    }

    func start(userId: String) async throws {
        try await serialized { [self] in
            try await performStart(userId: userId)
        }
    }

    func statusPublisher() -> AnyPublisher<AgentAccessConnectionStatus, Never> {
        statusSubject.eraseToAnyPublisher()
    }

    func stop() async {
        _ = try? await serialized { [self] in
            await performStop()
        }
    }

    func unregisterIdentity(userId: String) async {
        guard let fingerprint = await identityFingerprint(userId: userId) else { return }
        do {
            try await apiService.unregisterIdentity(fingerprint: fingerprint)
        } catch {
            errorReporter.log(error: error)
        }
    }

    // MARK: Private Methods

    /// Returns a copy of the current state.
    private func currentState() -> State {
        lock.lock()
        defer { lock.unlock() }
        return state
    }

    /// Updates the state.
    private func updateState(_ transform: (inout State) -> Void) {
        lock.lock()
        defer { lock.unlock() }
        transform(&state)
    }

    /// Handles a pairing event raised by the session handler.
    private func handlePairingEvent(_ event: AgentAccessPairingEvent) {
        switch event {
        case .failed,
             .paired,
             .rejected:
            updateState { $0.pendingPairing = nil }
        case .verifyFingerprint,
             .waitingForAgent:
            break
        }
        pairingSubject.send(event)
    }

    /// Starts the client. Must run inside `serialized`.
    private func performStart(userId: String) async throws {
        let current = currentState()
        if current.client != nil, current.userId == userId {
            if let fingerprint = await identityFingerprint(userId: userId) {
                await register(fingerprint: fingerprint)
            }
            return
        }
        await performStop()

        let storedRelayURL = try? await store.userData(userId: userId).relayURL
        let relayURL = AgentAccessRelayURL.resolve(stored: storedRelayURL, environment: environment)
        guard AgentAccessRelayURL.isValid(relayURL) else { throw AgentAccessError.invalidRelayURL }

        let handler = AgentAccessSessionHandler(
            approvalCenter: approvalCenter,
            errorReporter: errorReporter,
            onPairingEvent: { [weak self] event in self?.handlePairingEvent(event) },
            onStatus: { [weak self] status in
                guard let self, currentState().client != nil else { return }
                statusSubject.send(status)
            },
            store: store,
            timeProvider: timeProvider,
            userId: userId,
            vaultAccessor: vaultAccessor,
        )

        statusSubject.send(.connecting)
        do {
            let client = try sdkClientFactory.makeClient(relayURL: relayURL, handler: handler)
            updateState { state in
                state.client = client
                state.handler = handler
                state.userId = userId
            }

            let fingerprint = try await client.getIdentityFingerprint()
            try await store.update(userId: userId) { $0.identityFingerprint = fingerprint }
            await register(fingerprint: fingerprint)

            try await client.connect()
            statusSubject.send(.listening)
            await flightRecorder.log("[AgentAccess] Listening, identity \(fingerprint.prefix(8))")
        } catch {
            await performStop()
            statusSubject.send(.failed(message: String(describing: error)))
            throw error
        }
    }

    /// Stops the client. Must run inside `serialized`.
    private func performStop() async {
        let current = currentState()
        updateState { $0 = State() }
        await current.client?.close()
        approvalCenter.denyAll()
        approvalCenter.removeRules()
        statusSubject.send(.disabled)
    }

    /// Registers the identity with the server. Failures are not fatal.
    private func register(fingerprint: String) async {
        do {
            try await apiService.registerIdentity(fingerprint: fingerprint)
        } catch let error as ResponseValidationError where error.response.statusCode == 404 {
            // The feature is off on the server.
        } catch let error as ResponseValidationError where error.response.statusCode == 409 {
            await flightRecorder.log("[AgentAccess] Identity \(fingerprint.prefix(8)) is registered to another user")
        } catch {
            errorReporter.log(error: error)
        }
    }

    /// Runs the operation after any other serialized operation has finished.
    private func serialized<T: Sendable>(_ operation: @escaping @Sendable () async throws -> T) async throws -> T {
        let box = ValueBox<T>()
        try await serializer.enqueue(userId: "agent-access") {
            box.value = try await operation()
        }
        guard let value = box.value else { throw AgentAccessError.requestNotFound }
        return value
    }
}
