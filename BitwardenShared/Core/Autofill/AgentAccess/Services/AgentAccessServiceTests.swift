import BitwardenKit
import BitwardenKitMocks
import Combine
import Networking
import TestHelpers
import XCTest

@testable import BitwardenShared
@testable import BitwardenSharedMocks

class AgentAccessServiceTests: BitwardenTestCase {
    // MARK: Properties

    var apiService: MockAgentAccessAPIService!
    var approvalCenter: AgentAccessApprovalCenter!
    var client: MockAgentAccessSdkClient!
    var clientFactory: MockAgentAccessSdkClientFactory!
    var errorReporter: MockErrorReporter!
    var flightRecorder: MockFlightRecorder!
    var keychainRepository: InMemoryAgentAccessKeychainRepository!
    var store: DefaultAgentAccessStore!
    var subject: DefaultAgentAccessService!
    var timeProvider: MockTimeProvider!
    var vaultAccessor: MockAgentAccessVaultAccessor!

    let fingerprint = String(repeating: "ab", count: 32)

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        apiService = MockAgentAccessAPIService()
        timeProvider = MockTimeProvider(.mockTime(Date(timeIntervalSince1970: 1_700_000_000)))
        approvalCenter = AgentAccessApprovalCenter(timeProvider: timeProvider)
        client = MockAgentAccessSdkClient()
        client.getIdentityFingerprintReturnValue = fingerprint
        clientFactory = MockAgentAccessSdkClientFactory()
        clientFactory.makeClientReturnValue = client
        errorReporter = MockErrorReporter()
        flightRecorder = MockFlightRecorder()
        keychainRepository = InMemoryAgentAccessKeychainRepository()
        store = DefaultAgentAccessStore(keychainRepository: keychainRepository)
        vaultAccessor = MockAgentAccessVaultAccessor()
        makeSubject(environment: [:])
    }

    override func tearDown() {
        super.tearDown()
        apiService = nil
        approvalCenter = nil
        client = nil
        clientFactory = nil
        errorReporter = nil
        flightRecorder = nil
        keychainRepository = nil
        store = nil
        subject = nil
        timeProvider = nil
        vaultAccessor = nil
    }

    // MARK: Tests - start

    /// `start(userId:)` creates the client for the default relay, stores and registers the identity
    /// fingerprint, connects and publishes the listening status.
    func test_start() async throws {
        try await subject.start(userId: "1")

        XCTAssertEqual(clientFactory.makeClientReceivedArguments?.relayURL, AgentAccessConstants.defaultRelayURL)
        XCTAssertEqual(apiService.registerIdentityReceivedFingerprint, fingerprint)
        XCTAssertEqual(client.connectCallsCount, 1)
        XCTAssertEqual(subject.runningUserId, "1")
        let storedFingerprint = try await store.userData(userId: "1").identityFingerprint
        XCTAssertEqual(storedFingerprint, fingerprint)
        var iterator = subject.statusPublisher().values.makeAsyncIterator()
        let status = await iterator.next()
        XCTAssertEqual(status, .listening)
    }

    /// `start(userId:)` uses the relay URL stored for the user.
    func test_start_storedRelayURL() async throws {
        try await store.update(userId: "1") { $0.relayURL = "ws://localhost:8080" }

        try await subject.start(userId: "1")

        XCTAssertEqual(clientFactory.makeClientReceivedArguments?.relayURL, "ws://localhost:8080")
    }

    #if DEBUG
    /// `start(userId:)` uses the debug environment override when no relay URL is stored.
    func test_start_environmentRelayURL() async throws {
        makeSubject(environment: [AgentAccessConstants.debugRelayURLEnvironmentKey: "ws://10.0.0.1:9000"])

        try await subject.start(userId: "1")

        XCTAssertEqual(clientFactory.makeClientReceivedArguments?.relayURL, "ws://10.0.0.1:9000")
    }

    /// A stored relay URL wins over the debug environment override.
    func test_start_storedRelayURLWinsOverEnvironment() async throws {
        makeSubject(environment: [AgentAccessConstants.debugRelayURLEnvironmentKey: "ws://10.0.0.1:9000"])
        try await store.update(userId: "1") { $0.relayURL = "wss://example.com" }

        try await subject.start(userId: "1")

        XCTAssertEqual(clientFactory.makeClientReceivedArguments?.relayURL, "wss://example.com")
    }
    #endif

    /// `start(userId:)` only refreshes the registration when the client already runs for the user.
    func test_start_alreadyRunning() async throws {
        try await subject.start(userId: "1")
        try await subject.start(userId: "1")

        XCTAssertEqual(clientFactory.makeClientCallsCount, 1)
        XCTAssertEqual(client.connectCallsCount, 1)
        XCTAssertEqual(apiService.registerIdentityCallsCount, 2)
    }

    /// `start(userId:)` stops the client of another user first.
    func test_start_otherUser() async throws {
        try await subject.start(userId: "1")
        try await subject.start(userId: "2")

        XCTAssertEqual(clientFactory.makeClientCallsCount, 2)
        XCTAssertEqual(client.closeCallsCount, 1)
        XCTAssertEqual(subject.runningUserId, "2")
    }

    /// `start(userId:)` throws, clears the client and publishes a failure when connecting fails.
    func test_start_connectFails() async throws {
        client.connectThrowableError = AgentAccessError.sdk(message: "no relay")

        await assertAsyncThrows(error: AgentAccessError.sdk(message: "no relay")) {
            try await subject.start(userId: "1")
        }

        XCTAssertNil(subject.runningUserId)
        var iterator = subject.statusPublisher().values.makeAsyncIterator()
        let status = await iterator.next()
        guard case .failed = status else {
            return XCTFail("Expected a failed status, got \(String(describing: status))")
        }
    }

    /// `start(userId:)` keeps going when registration fails, and reports the error.
    func test_start_registrationFails() async throws {
        apiService.registerIdentityThrowableError = BitwardenTestError.example

        try await subject.start(userId: "1")

        XCTAssertEqual(client.connectCallsCount, 1)
        XCTAssertEqual(errorReporter.errors.count, 1)
    }

    /// `start(userId:)` ignores a 404 from registration, which means the feature is off on the server.
    func test_start_registrationNotFound() async throws {
        apiService.registerIdentityThrowableError = ResponseValidationError(response: .failure(statusCode: 404))

        try await subject.start(userId: "1")

        XCTAssertEqual(client.connectCallsCount, 1)
        XCTAssertTrue(errorReporter.errors.isEmpty)
    }

    /// `start(userId:)` logs a 409 from registration without reporting an error.
    @MainActor
    func test_start_registrationConflict() async throws {
        apiService.registerIdentityThrowableError = ResponseValidationError(response: .failure(statusCode: 409))

        try await subject.start(userId: "1")

        XCTAssertEqual(client.connectCallsCount, 1)
        XCTAssertTrue(errorReporter.errors.isEmpty)
        XCTAssertTrue(flightRecorder.logMessages.contains { $0.contains("registered to another user") })
    }

    // MARK: Tests - stop

    /// `stop()` closes the client, denies pending requests, drops rules and publishes disabled.
    func test_stop() async throws {
        try await subject.start(userId: "1")
        approvalCenter.addRule(
            connectionFingerprint: "a",
            connectionName: "A",
            query: .id("1"),
            cipherId: "c",
            duration: 60,
        )

        await subject.stop()

        XCTAssertEqual(client.closeCallsCount, 1)
        XCTAssertNil(subject.runningUserId)
        XCTAssertTrue(approvalCenter.autoApproveRules().isEmpty)
        var iterator = subject.statusPublisher().values.makeAsyncIterator()
        let status = await iterator.next()
        XCTAssertEqual(status, .disabled)
    }

    // MARK: Tests - ownsIdentity

    /// `ownsIdentity(userId:fingerprint:)` is true only for the stored fingerprint of that user.
    func test_ownsIdentity() async throws {
        try await subject.start(userId: "1")

        let own = await subject.ownsIdentity(userId: "1", fingerprint: fingerprint)
        let otherFingerprint = await subject.ownsIdentity(userId: "1", fingerprint: "other")
        let otherUser = await subject.ownsIdentity(userId: "2", fingerprint: fingerprint)
        XCTAssertTrue(own)
        XCTAssertFalse(otherFingerprint)
        XCTAssertFalse(otherUser)
    }

    // MARK: Tests - createPairing

    /// `createPairing(kind:name:)` throws when the client isn't running.
    func test_createPairing_notListening() async {
        await assertAsyncThrows(error: AgentAccessError.notListening) {
            _ = try await subject.createPairing(kind: .psk, name: "Codex")
        }
    }

    /// `createPairing(kind:name:)` creates an ephemeral PSK token and publishes waiting.
    func test_createPairing_psk() async throws {
        try await subject.start(userId: "1")
        client.getPskTokenReturnValue = "token"
        var events = subject.pairingEventsPublisher().values.makeAsyncIterator()

        let pairing = try await subject.createPairing(kind: .psk, name: "Codex")

        XCTAssertEqual(client.getPskTokenReceivedArguments?.name, "Codex")
        XCTAssertEqual(client.getPskTokenReceivedArguments?.reusable, false)
        XCTAssertEqual(pairing.kind, .psk)
        XCTAssertEqual(pairing.token, "token")
        XCTAssertEqual(pairing.name, "Codex")
        XCTAssertEqual(pairing.expiresAt, timeProvider.presentTime.addingTimeInterval(600))
        XCTAssertTrue(subject.hasPendingPairing)
        let event = await events.next()
        XCTAssertEqual(event, .waitingForAgent)
    }

    /// `createPairing(kind:name:)` creates a rendezvous code.
    func test_createPairing_rendezvous() async throws {
        try await subject.start(userId: "1")
        client.getRendezvousTokenReturnValue = "ABC-DEF-GHI"

        let pairing = try await subject.createPairing(kind: .rendezvous, name: "Codex")

        XCTAssertEqual(client.getRendezvousTokenReceivedName, "Codex")
        XCTAssertEqual(pairing.kind, .rendezvous)
        XCTAssertEqual(pairing.token, "ABC-DEF-GHI")
        XCTAssertEqual(pairing.expiresAt, timeProvider.presentTime.addingTimeInterval(300))
    }

    /// The pending pairing ends when the SDK reports the connection as established.
    func test_pairingCompletes() async throws {
        try await subject.start(userId: "1")
        client.getPskTokenReturnValue = "token"
        _ = try await subject.createPairing(kind: .psk, name: "Codex")
        var events = subject.pairingEventsPublisher().values.makeAsyncIterator()

        let handler = try XCTUnwrap(clientFactory.makeClientReceivedArguments?.handler)
        await onSdkThread {
            handler.handle(auditEvent: AgentAccessSdkAuditEvent(
                kind: .connectionEstablished,
                remoteFingerprint: "fp",
                remoteName: "Codex",
                query: nil,
                cipherId: nil,
            ))
        }

        var event = await events.next()
        if event == .waitingForAgent {
            event = await events.next()
        }
        guard case .paired = event else { return XCTFail("Expected paired, got \(String(describing: event))") }
        XCTAssertFalse(subject.hasPendingPairing)
    }

    // MARK: Tests - restart and unregister

    /// `restart()` closes and reconnects the running client.
    func test_restart() async throws {
        try await subject.start(userId: "1")

        await subject.restart()

        XCTAssertEqual(client.closeCallsCount, 1)
        XCTAssertEqual(client.connectCallsCount, 2)
    }

    /// `restart()` does nothing when the client isn't running.
    func test_restart_notRunning() async {
        await subject.restart()

        XCTAssertFalse(client.connectCalled)
    }

    /// `unregisterIdentity(userId:)` removes the registration of the stored fingerprint.
    func test_unregisterIdentity() async throws {
        try await subject.start(userId: "1")

        await subject.unregisterIdentity(userId: "1")

        XCTAssertEqual(apiService.unregisterIdentityReceivedFingerprint, fingerprint)
    }

    /// `unregisterIdentity(userId:)` does nothing when the user has no identity.
    func test_unregisterIdentity_noIdentity() async {
        await subject.unregisterIdentity(userId: "1")

        XCTAssertFalse(apiService.unregisterIdentityCalled)
    }

    // MARK: Private

    private func makeSubject(environment: [String: String]) {
        subject = DefaultAgentAccessService(
            apiService: apiService,
            approvalCenter: approvalCenter,
            environment: environment,
            errorReporter: errorReporter,
            flightRecorder: flightRecorder,
            sdkClientFactory: clientFactory,
            store: store,
            timeProvider: timeProvider,
            vaultAccessor: vaultAccessor,
        )
    }
}
