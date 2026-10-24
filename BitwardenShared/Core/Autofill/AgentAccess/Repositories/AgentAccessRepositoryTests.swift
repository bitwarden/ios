// swiftlint:disable file_length

import BitwardenKit
import BitwardenKitMocks
import Combine
import TestHelpers
import UIKit
import XCTest

@testable import BitwardenShared
@testable import BitwardenSharedMocks

class AgentAccessRepositoryTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: Properties

    var application: MockApplication!
    var approvalCenter: AgentAccessApprovalCenter!
    var configService: MockConfigService!
    var errorReporter: MockErrorReporter!
    var flightRecorder: MockFlightRecorder!
    var keychainRepository: InMemoryAgentAccessKeychainRepository!
    var service: MockAgentAccessService!
    var stateService: MockStateService!
    var store: DefaultAgentAccessStore!
    var subject: DefaultAgentAccessRepository!
    var timeProvider: MockTimeProvider!
    var vaultAccessor: MockAgentAccessVaultAccessor!

    let credential = AgentAccessSdkCredential(
        username: "user",
        password: "secret",
        credentialId: "cipher-1",
        domain: "example.com",
    )

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        application = MockApplication()
        timeProvider = MockTimeProvider(.mockTime(Date(timeIntervalSince1970: 1_700_000_000)))
        approvalCenter = AgentAccessApprovalCenter(timeProvider: timeProvider)
        configService = MockConfigService()
        configService.featureFlagsBool[.agentAccess] = true
        errorReporter = MockErrorReporter()
        flightRecorder = MockFlightRecorder()
        keychainRepository = InMemoryAgentAccessKeychainRepository()
        service = MockAgentAccessService()
        stateService = MockStateService()
        stateService.activeAccount = .fixture()
        store = DefaultAgentAccessStore(keychainRepository: keychainRepository)
        vaultAccessor = MockAgentAccessVaultAccessor()
        subject = DefaultAgentAccessRepository(
            application: application,
            approvalCenter: approvalCenter,
            configService: configService,
            environment: [:],
            errorReporter: errorReporter,
            flightRecorder: flightRecorder,
            service: service,
            stateService: stateService,
            store: store,
            timeProvider: timeProvider,
            vaultAccessor: vaultAccessor,
        )
    }

    override func tearDown() {
        super.tearDown()
        application = nil
        approvalCenter = nil
        configService = nil
        errorReporter = nil
        flightRecorder = nil
        keychainRepository = nil
        service = nil
        stateService = nil
        store = nil
        subject = nil
        timeProvider = nil
        vaultAccessor = nil
    }

    // MARK: Tests - Settings

    /// `isFeatureEnabled()` reflects the feature flag.
    @MainActor
    func test_isFeatureEnabled() async {
        let enabled = await subject.isFeatureEnabled()
        XCTAssertTrue(enabled)

        configService.featureFlagsBool[.agentAccess] = false
        let disabled = await subject.isFeatureEnabled()
        XCTAssertFalse(disabled)
    }

    /// `isListeningEnabled()` is true only when the flag is on and the user turned listening on.
    @MainActor
    func test_isListeningEnabled() async throws {
        let initial = await subject.isListeningEnabled()
        XCTAssertFalse(initial)

        try await store.update(userId: "1") { $0.listeningEnabled = true }
        let enabled = await subject.isListeningEnabled()
        XCTAssertTrue(enabled)

        configService.featureFlagsBool[.agentAccess] = false
        let flagOff = await subject.isListeningEnabled()
        XCTAssertFalse(flagOff)
    }

    /// `setListeningEnabled(_:)` throws when the feature flag is off.
    @MainActor
    func test_setListeningEnabled_flagOff() async {
        configService.featureFlagsBool[.agentAccess] = false

        await assertAsyncThrows(error: AgentAccessError.featureDisabled) {
            try await subject.setListeningEnabled(true)
        }

        XCTAssertFalse(service.startCalled)
    }

    /// `setListeningEnabled(_:)` throws when there is no active account.
    func test_setListeningEnabled_noAccount() async {
        stateService.activeAccount = nil

        await assertAsyncThrows(error: AgentAccessError.noActiveAccount) {
            try await subject.setListeningEnabled(true)
        }
    }

    /// `setListeningEnabled(_:)` saves the setting and starts the client when turned on.
    func test_setListeningEnabled_on() async throws {
        try await subject.setListeningEnabled(true)

        XCTAssertEqual(service.startReceivedUserId, "1")
        let data = try await store.userData(userId: "1")
        XCTAssertTrue(data.listeningEnabled)
    }

    /// `setListeningEnabled(_:)` saves the setting, unregisters and stops when turned off.
    func test_setListeningEnabled_off() async throws {
        try await store.update(userId: "1") { $0.listeningEnabled = true }

        try await subject.setListeningEnabled(false)

        XCTAssertEqual(service.unregisterIdentityReceivedUserId, "1")
        XCTAssertEqual(service.stopCallsCount, 1)
        let data = try await store.userData(userId: "1")
        XCTAssertFalse(data.listeningEnabled)
    }

    /// `relayURL()` returns the default, then the stored URL.
    func test_relayURL() async throws {
        let initial = await subject.relayURL()
        XCTAssertEqual(initial, AgentAccessConstants.defaultRelayURL)

        try await store.update(userId: "1") { $0.relayURL = "ws://localhost:8080" }
        let stored = await subject.relayURL()
        XCTAssertEqual(stored, "ws://localhost:8080")
    }

    /// `setRelayURL(_:)` rejects URLs that aren't `ws://` or `wss://`.
    func test_setRelayURL_invalid() async throws {
        for url in ["https://example.com", "example.com", "ws://", ""] {
            await assertAsyncThrows(error: AgentAccessError.invalidRelayURL) {
                try await subject.setRelayURL(url)
            }
        }
        let data = try await store.userData(userId: "1")
        XCTAssertNil(data.relayURL)
    }

    /// `setRelayURL(_:)` saves the URL and reconnects when the client is running.
    func test_setRelayURL_reconnects() async throws {
        service.runningUserId = "1"

        try await subject.setRelayURL("wss://relay.example.com")

        let data = try await store.userData(userId: "1")
        XCTAssertEqual(data.relayURL, "wss://relay.example.com")
        XCTAssertEqual(service.stopCallsCount, 1)
        XCTAssertEqual(service.startReceivedUserId, "1")
    }

    /// `setRelayURL(_:)` only saves the URL when the client isn't running.
    func test_setRelayURL_notRunning() async throws {
        try await subject.setRelayURL("ws://localhost:8080")

        XCTAssertFalse(service.startCalled)
        XCTAssertFalse(service.stopCalled)
    }

    // MARK: Tests - Pairing

    /// `createPairing(kind:name:)` enables listening and starts the client when it isn't running.
    func test_createPairing_startsClient() async throws {
        let pairing = AgentAccessPairing(
            kind: .psk,
            token: "token",
            name: "Codex",
            createdAt: timeProvider.presentTime,
            expiresAt: timeProvider.presentTime.addingTimeInterval(600),
        )
        service.createPairingReturnValue = pairing

        let result = try await subject.createPairing(kind: .psk, name: "Codex")

        XCTAssertEqual(result, pairing)
        XCTAssertEqual(service.startReceivedUserId, "1")
        XCTAssertEqual(service.createPairingReceivedArguments?.kind, .psk)
        XCTAssertEqual(service.createPairingReceivedArguments?.name, "Codex")
        let data = try await store.userData(userId: "1")
        XCTAssertTrue(data.listeningEnabled)
    }

    /// `createPairing(kind:name:)` doesn't restart a client that already runs for the account.
    func test_createPairing_alreadyRunning() async throws {
        service.runningUserId = "1"
        service.createPairingReturnValue = AgentAccessPairing(
            kind: .rendezvous,
            token: "ABC-DEF-GHI",
            name: "Codex",
            createdAt: timeProvider.presentTime,
            expiresAt: timeProvider.presentTime,
        )

        _ = try await subject.createPairing(kind: .rendezvous, name: "Codex")

        XCTAssertFalse(service.startCalled)
    }

    /// `answerFingerprintVerification(id:approved:)` forwards the answer to the service.
    func test_answerFingerprintVerification() {
        subject.answerFingerprintVerification(id: "v1", approved: true)

        XCTAssertEqual(service.answerFingerprintVerificationReceivedArguments?.id, "v1")
        XCTAssertEqual(service.answerFingerprintVerificationReceivedArguments?.approved, true)
    }

    // MARK: Tests - Connections

    /// `connections()` returns the paired agents, most recently used first.
    func test_connections() async throws {
        try await store.update(userId: "1") { data in
            data.connections = [
                AgentAccessStoredConnection(
                    fingerprint: "old",
                    name: "Old",
                    cachedAt: 100,
                    lastConnectedAt: 200,
                    transportState: nil,
                ),
                AgentAccessStoredConnection(
                    fingerprint: "new",
                    name: nil,
                    cachedAt: 300,
                    lastConnectedAt: 400,
                    transportState: nil,
                ),
            ]
        }

        let connections = try await subject.connections()

        XCTAssertEqual(connections.map(\.fingerprint), ["new", "old"])
        XCTAssertEqual(connections.first?.pairedAt, Date(timeIntervalSince1970: 300))
        XCTAssertEqual(connections.last?.name, "Old")
    }

    /// `revokeConnection(fingerprint:)` removes the connection and its rules, denies its pending
    /// requests, restarts the client and writes an audit entry.
    func test_revokeConnection() async throws {
        try await store.update(userId: "1") { data in
            data.connections = [
                AgentAccessStoredConnection(
                    fingerprint: "fp",
                    name: "Codex",
                    cachedAt: 1,
                    lastConnectedAt: 1,
                    transportState: Data([1]),
                ),
                AgentAccessStoredConnection(
                    fingerprint: "other",
                    name: "Other",
                    cachedAt: 1,
                    lastConnectedAt: 1,
                    transportState: nil,
                ),
            ]
        }
        approvalCenter.addRule(
            connectionFingerprint: "fp",
            connectionName: "Codex",
            query: .id("1"),
            cipherId: "c",
            duration: 60,
        )
        approvalCenter.addRule(
            connectionFingerprint: "other",
            connectionName: "Other",
            query: .id("1"),
            cipherId: "c",
            duration: 60,
        )
        service.runningUserId = "1"
        let request = makeRequest(id: "r1", fingerprint: "fp")
        async let outcome = onSdkThread { self.approvalCenter.requestApproval(request) }
        let pending = await waitUntil { !self.approvalCenter.pendingRequests().isEmpty }
        XCTAssertTrue(pending)

        try await subject.revokeConnection(fingerprint: "fp")

        let denied = await outcome
        XCTAssertEqual(denied, .denied)
        let data = try await store.userData(userId: "1")
        XCTAssertEqual(data.connections.map(\.fingerprint), ["other"])
        XCTAssertEqual(approvalCenter.autoApproveRules().map(\.connectionFingerprint), ["other"])
        XCTAssertEqual(service.restartCallsCount, 1)
        XCTAssertEqual(data.audit.first?.kind, .connectionRevoked)
        XCTAssertEqual(data.audit.first?.connectionName, "Codex")
    }

    /// `revokeConnection(fingerprint:)` doesn't restart a client that isn't running.
    func test_revokeConnection_notRunning() async throws {
        try await subject.revokeConnection(fingerprint: "fp")

        XCTAssertFalse(service.restartCalled)
    }

    // MARK: Tests - Approvals

    /// `candidates(for:)` asks the vault for the logins matching the request.
    func test_candidates() async throws {
        let candidate = AgentAccessCandidate(id: "c1", name: "Example", username: "u", uri: "https://example.com")
        vaultAccessor.candidatesReturnValue = [candidate]
        let request = makeRequest(id: "r1")
        async let outcome = onSdkThread { self.approvalCenter.requestApproval(request) }
        let pending = await waitUntil { !self.approvalCenter.pendingRequests().isEmpty }
        XCTAssertTrue(pending)

        let result = try await subject.candidates(for: "r1")

        XCTAssertEqual(result, [candidate])
        XCTAssertEqual(vaultAccessor.candidatesReceivedArguments?.query, .domain("example.com"))
        XCTAssertEqual(vaultAccessor.candidatesReceivedArguments?.userId, "1")
        approvalCenter.denyAll()
        _ = await outcome
    }

    /// `candidates(for:)` throws for an unknown request.
    func test_candidates_notFound() async {
        await assertAsyncThrows(error: AgentAccessError.requestNotFound) {
            _ = try await subject.candidates(for: "missing")
        }
    }

    /// `answer(requestId:decision:)` delivers the credential of the picked item.
    func test_answer_approve() async throws {
        vaultAccessor.credentialReturnValue = credential
        vaultAccessor.candidatesReturnValue = [candidate(id: "cipher-1")]
        let request = makeRequest(id: "r1")
        async let outcome = onSdkThread { self.approvalCenter.requestApproval(request) }
        let pending = await waitUntil { !self.approvalCenter.pendingRequests().isEmpty }
        XCTAssertTrue(pending)

        try await subject.answer(requestId: "r1", decision: .approve(cipherId: "cipher-1", autoApproveMinutes: nil))

        let result = await outcome
        XCTAssertEqual(result, .approved(credential))
        XCTAssertEqual(vaultAccessor.credentialReceivedArguments?.cipherId, "cipher-1")
        XCTAssertTrue(approvalCenter.autoApproveRules().isEmpty)
    }

    /// `answer(requestId:decision:)` creates an automatic approval rule when asked to remember.
    func test_answer_approveWithAutoApprove() async throws {
        vaultAccessor.credentialReturnValue = credential
        vaultAccessor.candidatesReturnValue = [candidate(id: "cipher-1")]
        let request = makeRequest(id: "r1")
        async let outcome = onSdkThread { self.approvalCenter.requestApproval(request) }
        let pending = await waitUntil { !self.approvalCenter.pendingRequests().isEmpty }
        XCTAssertTrue(pending)

        try await subject.answer(requestId: "r1", decision: .approve(cipherId: "cipher-1", autoApproveMinutes: 10))

        _ = await outcome
        let rule = try XCTUnwrap(approvalCenter.autoApproveRules().first)
        XCTAssertEqual(rule.cipherId, "cipher-1")
        XCTAssertEqual(rule.connectionFingerprint, "fp")
        XCTAssertEqual(rule.query, .domain("example.com"))
        XCTAssertEqual(rule.expiresAt, timeProvider.presentTime.addingTimeInterval(600))
    }

    /// `answer(requestId:decision:)` ignores a remember duration that isn't offered.
    func test_answer_approveWithInvalidDuration() async throws {
        vaultAccessor.credentialReturnValue = credential
        vaultAccessor.candidatesReturnValue = [candidate(id: "cipher-1")]
        let request = makeRequest(id: "r1")
        async let outcome = onSdkThread { self.approvalCenter.requestApproval(request) }
        let pending = await waitUntil { !self.approvalCenter.pendingRequests().isEmpty }
        XCTAssertTrue(pending)

        try await subject.answer(requestId: "r1", decision: .approve(cipherId: "cipher-1", autoApproveMinutes: 7))

        _ = await outcome
        XCTAssertTrue(approvalCenter.autoApproveRules().isEmpty)
    }

    /// `answer(requestId:decision:)` leaves the request pending when the item can't be shared.
    func test_answer_approveCipherNotFound() async throws {
        vaultAccessor.candidatesReturnValue = [candidate(id: "gone")]
        vaultAccessor.credentialThrowableError = AgentAccessError.cipherNotFound
        let request = makeRequest(id: "r1")
        async let outcome = onSdkThread { self.approvalCenter.requestApproval(request) }
        let pending = await waitUntil { !self.approvalCenter.pendingRequests().isEmpty }
        XCTAssertTrue(pending)

        await assertAsyncThrows(error: AgentAccessError.cipherNotFound) {
            try await subject.answer(requestId: "r1", decision: .approve(cipherId: "gone", autoApproveMinutes: nil))
        }

        XCTAssertNotNil(approvalCenter.pendingRequest(id: "r1"))
        approvalCenter.denyAll()
        _ = await outcome
    }

    /// `answer(requestId:decision:)` rejects an approval for an item that isn't a candidate for the request.
    func test_answer_approveNotCandidate() async throws {
        vaultAccessor.candidatesReturnValue = [candidate(id: "cipher-1")]
        let request = makeRequest(id: "r1")
        async let outcome = onSdkThread { self.approvalCenter.requestApproval(request) }
        let pending = await waitUntil { !self.approvalCenter.pendingRequests().isEmpty }
        XCTAssertTrue(pending)

        await assertAsyncThrows(error: AgentAccessError.cipherNotFound) {
            try await subject.answer(requestId: "r1", decision: .approve(cipherId: "other", autoApproveMinutes: 10))
        }

        XCTAssertNil(vaultAccessor.credentialReceivedArguments)
        XCTAssertNotNil(approvalCenter.pendingRequest(id: "r1"))
        XCTAssertTrue(approvalCenter.autoApproveRules().isEmpty)
        approvalCenter.denyAll()
        _ = await outcome
    }

    /// `answer(requestId:decision:)` denies the request.
    func test_answer_deny() async throws {
        let request = makeRequest(id: "r1")
        async let outcome = onSdkThread { self.approvalCenter.requestApproval(request) }
        let pending = await waitUntil { !self.approvalCenter.pendingRequests().isEmpty }
        XCTAssertTrue(pending)

        try await subject.answer(requestId: "r1", decision: .deny)

        let result = await outcome
        XCTAssertEqual(result, .denied)
    }

    /// `answer(requestId:decision:)` throws for an unknown request.
    func test_answer_notFound() async {
        await assertAsyncThrows(error: AgentAccessError.requestNotFound) {
            try await subject.answer(requestId: "missing", decision: .deny)
        }
    }

    /// `answer(requestId:decision:)` throws once the approval window has passed.
    func test_answer_expired() async throws {
        let request = makeRequest(id: "r1", window: 0.5)
        async let outcome = onSdkThread { self.approvalCenter.requestApproval(request) }
        let pending = await waitUntil { !self.approvalCenter.pendingRequests().isEmpty }
        XCTAssertTrue(pending)

        timeProvider.timeConfig = .mockTime(Date(timeIntervalSince1970: 1_700_000_010))

        await assertAsyncThrows(error: AgentAccessError.requestExpired) {
            try await subject.answer(requestId: "r1", decision: .deny)
        }
        _ = await outcome
    }

    /// `removeAutoApproveRule(id:)` removes the rule.
    func test_removeAutoApproveRule() async throws {
        approvalCenter.addRule(
            connectionFingerprint: "fp",
            connectionName: "Codex",
            query: .id("1"),
            cipherId: "c",
            duration: 60,
        )
        let rules = await subject.autoApproveRules()
        XCTAssertEqual(rules.count, 1)

        try await subject.removeAutoApproveRule(id: XCTUnwrap(rules.first).id)

        let remaining = await subject.autoApproveRules()
        XCTAssertTrue(remaining.isEmpty)
    }

    // MARK: Tests - Audit

    /// `auditLog()` returns the entries newest first, and `clearAuditLog()` empties it.
    func test_auditLog() async throws {
        let first = makeAuditEntry(kind: .credentialRequested)
        let second = makeAuditEntry(kind: .credentialApproved)
        try await store.appendAudit(first, userId: "1")
        try await store.appendAudit(second, userId: "1")

        let log = try await subject.auditLog()
        XCTAssertEqual(log, [second, first])

        try await subject.clearAuditLog()
        let cleared = try await subject.auditLog()
        XCTAssertTrue(cleared.isEmpty)
    }

    // MARK: Tests - Lifecycle

    /// `appDidBecomeActive()` starts the client when the flag is on and listening is enabled.
    func test_appDidBecomeActive_starts() async throws {
        try await store.update(userId: "1") { $0.listeningEnabled = true }

        await subject.appDidBecomeActive()

        XCTAssertEqual(service.startReceivedUserId, "1")
    }

    /// `appDidBecomeActive()` doesn't start the client when listening isn't enabled.
    func test_appDidBecomeActive_notListening() async {
        await subject.appDidBecomeActive()

        XCTAssertFalse(service.startCalled)
    }

    /// `appDidBecomeActive()` doesn't start the client when the flag is off.
    @MainActor
    func test_appDidBecomeActive_flagOff() async throws {
        try await store.update(userId: "1") { $0.listeningEnabled = true }
        configService.featureFlagsBool[.agentAccess] = false

        await subject.appDidBecomeActive()

        XCTAssertFalse(service.startCalled)
    }

    /// `appDidBecomeActive()` reports an error from starting the client.
    func test_appDidBecomeActive_startFails() async throws {
        try await store.update(userId: "1") { $0.listeningEnabled = true }
        service.startThrowableError = BitwardenTestError.example

        await subject.appDidBecomeActive()

        XCTAssertEqual(errorReporter.errors.count, 1)
    }

    /// `appDidBecomeActive()` only records expected start failures, like an unreachable relay.
    func test_appDidBecomeActive_startFailsWithAgentAccessError() async throws {
        try await store.update(userId: "1") { $0.listeningEnabled = true }
        service.startThrowableError = AgentAccessError.sdk(message: "relay unreachable")

        await subject.appDidBecomeActive()

        XCTAssertTrue(errorReporter.errors.isEmpty)
    }

    /// `appDidEnterBackground()` stops the client when no pairing is pending.
    func test_appDidEnterBackground_stops() async {
        service.hasPendingPairing = false

        await subject.appDidEnterBackground()

        XCTAssertEqual(service.stopCallsCount, 1)
        XCTAssertNil(application.beginBackgroundTaskName)
    }

    /// `appDidEnterBackground()` keeps the client and requests background time while a pairing is pending.
    func test_appDidEnterBackground_pendingPairing() async {
        service.hasPendingPairing = true
        service.pairingEventsPublisherReturnValue = Empty().eraseToAnyPublisher()
        application.beginBackgroundTaskIdentifier = UIBackgroundTaskIdentifier(rawValue: 42)

        await subject.appDidEnterBackground()

        XCTAssertFalse(service.stopCalled)
        XCTAssertEqual(application.beginBackgroundTaskName, "AgentAccessPairing")

        await subject.appDidBecomeActive()

        XCTAssertEqual(application.endBackgroundTaskIdentifier, UIBackgroundTaskIdentifier(rawValue: 42))
        XCTAssertFalse(service.stopCalled)
    }

    /// `activeAccountChanged(userId:)` stops the client and starts it for the new account.
    func test_activeAccountChanged() async throws {
        try await store.update(userId: "2") { $0.listeningEnabled = true }

        await subject.activeAccountChanged(userId: "2")

        XCTAssertEqual(service.stopCallsCount, 1)
        XCTAssertEqual(service.startReceivedUserId, "2")
    }

    /// `activeAccountChanged(userId:)` only stops the client when the user logged out.
    func test_activeAccountChanged_loggedOut() async {
        await subject.activeAccountChanged(userId: nil)

        XCTAssertEqual(service.stopCallsCount, 1)
        XCTAssertFalse(service.startCalled)
    }

    /// `notificationTapped(userId:)` starts the client for the account.
    func test_notificationTapped() async throws {
        try await store.update(userId: "2") { $0.listeningEnabled = true }

        await subject.notificationTapped(userId: "2")

        XCTAssertEqual(service.startReceivedUserId, "2")
    }

    // MARK: Private

    private func makeAuditEntry(kind: AgentAccessAuditKind) -> AgentAccessAuditEntry {
        AgentAccessAuditEntry(
            id: UUID(),
            date: Date(timeIntervalSince1970: 1_700_000_000),
            kind: kind,
            connectionFingerprint: "fp",
            connectionName: "Codex",
            query: nil,
            cipherId: nil,
        )
    }

    private func candidate(id: String) -> AgentAccessCandidate {
        AgentAccessCandidate(id: id, name: "Example", username: "u", uri: "https://example.com")
    }

    private func makeRequest(
        id: String,
        fingerprint: String = "fp",
        window: TimeInterval = 30,
    ) -> AgentAccessApprovalRequest {
        let now = timeProvider.presentTime
        return AgentAccessApprovalRequest(
            id: id,
            userId: "1",
            connectionFingerprint: fingerprint,
            connectionName: "Codex",
            query: .domain("example.com"),
            receivedAt: now,
            expiresAt: now.addingTimeInterval(window),
        )
    }
}
