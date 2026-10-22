import BitwardenKit
import BitwardenKitMocks
import XCTest

@testable import BitwardenShared
@testable import BitwardenSharedMocks

class AgentAccessSessionHandlerTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: Properties

    var approvalCenter: AgentAccessApprovalCenter!
    var errorReporter: MockErrorReporter!
    var keychainRepository: InMemoryAgentAccessKeychainRepository!
    var pairingEvents: ThreadSafeLog<AgentAccessPairingEvent>!
    var statuses: ThreadSafeLog<AgentAccessConnectionStatus>!
    var store: DefaultAgentAccessStore!
    var subject: AgentAccessSessionHandler!
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
        timeProvider = MockTimeProvider(.mockTime(Date(timeIntervalSince1970: 1_700_000_000)))
        approvalCenter = AgentAccessApprovalCenter(timeProvider: timeProvider)
        errorReporter = MockErrorReporter()
        keychainRepository = InMemoryAgentAccessKeychainRepository()
        pairingEvents = ThreadSafeLog()
        statuses = ThreadSafeLog()
        store = DefaultAgentAccessStore(keychainRepository: keychainRepository)
        vaultAccessor = MockAgentAccessVaultAccessor()
        subject = AgentAccessSessionHandler(
            approvalCenter: approvalCenter,
            errorReporter: errorReporter,
            onPairingEvent: { [pairingEvents] in pairingEvents?.append($0) },
            onStatus: { [statuses] in statuses?.append($0) },
            store: store,
            timeProvider: timeProvider,
            userId: "1",
            vaultAccessor: vaultAccessor,
        )
    }

    override func tearDown() {
        super.tearDown()
        approvalCenter = nil
        errorReporter = nil
        keychainRepository = nil
        pairingEvents = nil
        statuses = nil
        store = nil
        subject = nil
        timeProvider = nil
        vaultAccessor = nil
    }

    // MARK: Tests - Storage

    /// The identity is saved and loaded through the store.
    func test_identity_roundTrip() async throws {
        let initial = await onSdkThread { self.subject.loadIdentity() }
        XCTAssertNil(initial)

        await onSdkThread { try? self.subject.saveIdentity(Data([7, 8])) }

        let loaded = await onSdkThread { self.subject.loadIdentity() }
        XCTAssertEqual(loaded, Data([7, 8]))
    }

    /// Connections are saved, replaced, updated and listed through the store.
    func test_connections() async throws {
        let connection = AgentAccessStoredConnection(
            fingerprint: "fp",
            name: "Agent",
            cachedAt: 10,
            lastConnectedAt: 10,
            transportState: Data([1]),
        )

        await onSdkThread { try? self.subject.saveConnection(connection) }
        var replacement = connection
        replacement.transportState = Data([2])
        await onSdkThread { try? self.subject.saveConnection(replacement) }
        await onSdkThread { try? self.subject.updateConnection(fingerprint: "fp", lastConnectedAt: 99) }

        let listed = await onSdkThread { self.subject.listConnections() }
        XCTAssertEqual(listed.count, 1)
        XCTAssertEqual(listed.first?.transportState, Data([2]))
        XCTAssertEqual(listed.first?.lastConnectedAt, 99)
        let fetched = await onSdkThread { self.subject.connection(fingerprint: "fp") }
        XCTAssertEqual(fetched?.name, "Agent")
        let missing = await onSdkThread { self.subject.connection(fingerprint: "other") }
        XCTAssertNil(missing)
    }

    // MARK: Tests - Credential Requests

    /// `credential(for:remoteFingerprint:)` waits for the user and returns the approved credential.
    func test_credential_approved() async throws {
        try await store.update(userId: "1") { data in
            data.connections = [
                AgentAccessStoredConnection(
                    fingerprint: "fp",
                    name: "Codex",
                    cachedAt: 1,
                    lastConnectedAt: 1,
                    transportState: nil,
                ),
            ]
        }

        async let result = onSdkThread { self.subject.credential(for: .domain("example.com"), remoteFingerprint: "fp") }
        let appeared = await waitUntil { !self.approvalCenter.pendingRequests().isEmpty }
        XCTAssertTrue(appeared)
        let request = try XCTUnwrap(approvalCenter.pendingRequests().first)
        XCTAssertEqual(request.connectionName, "Codex")
        XCTAssertEqual(request.query, .domain("example.com"))
        XCTAssertEqual(request.userId, "1")
        XCTAssertEqual(request.expiresAt, request.receivedAt.addingTimeInterval(AgentAccessConstants.approvalTimeout))

        approvalCenter.resolve(id: request.id, outcome: .approved(credential))

        let returned = await result
        XCTAssertEqual(returned, credential)
    }

    /// `credential(for:remoteFingerprint:)` returns `nil` when the user denies.
    func test_credential_denied() async throws {
        async let result = onSdkThread { self.subject.credential(for: .id("x"), remoteFingerprint: "abcdef0123") }
        let appeared = await waitUntil { !self.approvalCenter.pendingRequests().isEmpty }
        XCTAssertTrue(appeared)
        let request = try XCTUnwrap(approvalCenter.pendingRequests().first)
        XCTAssertEqual(request.connectionName, "abcdef01")

        approvalCenter.resolve(id: request.id, outcome: .denied)

        let returned = await result
        XCTAssertNil(returned)
    }

    /// Stopping the session by denying all requests unblocks the SDK thread.
    func test_credential_denyAllUnblocks() async throws {
        async let result = onSdkThread { self.subject.credential(for: .search("x"), remoteFingerprint: "fp") }
        let appeared = await waitUntil { !self.approvalCenter.pendingRequests().isEmpty }
        XCTAssertTrue(appeared)

        approvalCenter.denyAll()

        let returned = await result
        XCTAssertNil(returned)
    }

    /// `credential(for:remoteFingerprint:)` answers without asking when an automatic approval rule
    /// matches and the vault is unlocked.
    func test_credential_autoApproved() async throws {
        approvalCenter.addRule(
            connectionFingerprint: "fp",
            connectionName: "Codex",
            query: .domain("example.com"),
            cipherId: "cipher-1",
            duration: 60,
        )
        vaultAccessor.isVaultUnlockedReturnValue = true
        vaultAccessor.credentialReturnValue = credential

        let returned = await onSdkThread {
            self.subject.credential(for: .domain("example.com"), remoteFingerprint: "fp")
        }

        XCTAssertEqual(returned, credential)
        XCTAssertTrue(approvalCenter.pendingRequests().isEmpty)
        XCTAssertEqual(vaultAccessor.credentialReceivedArguments?.cipherId, "cipher-1")

        await onSdkThread {
            self.subject.handle(auditEvent: AgentAccessSdkAuditEvent(
                kind: .credentialApproved,
                remoteFingerprint: "fp",
                remoteName: nil,
                query: .domain("example.com"),
                cipherId: "cipher-1",
            ))
        }
        let audit = try await store.userData(userId: "1").audit
        XCTAssertEqual(audit.map(\.kind), [.credentialAutoApproved])
    }

    /// `credential(for:remoteFingerprint:)` asks the user when a rule matches but the vault is locked.
    func test_credential_ruleWithLockedVaultAsksUser() async throws {
        approvalCenter.addRule(
            connectionFingerprint: "fp",
            connectionName: "Codex",
            query: .domain("example.com"),
            cipherId: "cipher-1",
            duration: 60,
        )
        vaultAccessor.isVaultUnlockedReturnValue = false

        async let result = onSdkThread { self.subject.credential(for: .domain("example.com"), remoteFingerprint: "fp") }
        let appeared = await waitUntil { !self.approvalCenter.pendingRequests().isEmpty }
        XCTAssertTrue(appeared)
        approvalCenter.denyAll()

        let returned = await result
        XCTAssertNil(returned)
        XCTAssertFalse(vaultAccessor.credentialCalled)
    }

    /// A failing automatic approval removes the rule and asks the user.
    func test_credential_ruleFailureFallsBackToUser() async throws {
        approvalCenter.addRule(
            connectionFingerprint: "fp",
            connectionName: "Codex",
            query: .domain("example.com"),
            cipherId: "gone",
            duration: 60,
        )
        vaultAccessor.isVaultUnlockedReturnValue = true
        vaultAccessor.credentialThrowableError = AgentAccessError.cipherNotFound

        async let result = onSdkThread { self.subject.credential(for: .domain("example.com"), remoteFingerprint: "fp") }
        let appeared = await waitUntil { !self.approvalCenter.pendingRequests().isEmpty }
        XCTAssertTrue(appeared)
        approvalCenter.denyAll()

        let returned = await result
        XCTAssertNil(returned)
        XCTAssertTrue(approvalCenter.autoApproveRules().isEmpty)
    }

    // MARK: Tests - Audit and Pairing

    /// A credential approval from the SDK is audited as approved, without credential values.
    func test_handleAuditEvent_approved() async throws {
        await onSdkThread {
            self.subject.handle(auditEvent: AgentAccessSdkAuditEvent(
                kind: .credentialApproved,
                remoteFingerprint: "fp",
                remoteName: nil,
                query: .domain("example.com"),
                cipherId: "cipher-1",
            ))
        }

        let entry = try await XCTUnwrap(store.userData(userId: "1").audit.first)
        XCTAssertEqual(entry.kind, .credentialApproved)
        XCTAssertEqual(entry.connectionFingerprint, "fp")
        XCTAssertEqual(entry.query, .domain("example.com"))
        XCTAssertEqual(entry.cipherId, "cipher-1")
    }

    /// A connection established by the SDK is audited and published as paired.
    func test_handleAuditEvent_connectionEstablished() async throws {
        await onSdkThread {
            try? self.subject.saveConnection(AgentAccessStoredConnection(
                fingerprint: "fp",
                name: "Codex",
                cachedAt: 100,
                lastConnectedAt: 200,
                transportState: nil,
            ))
        }

        await onSdkThread {
            self.subject.handle(auditEvent: AgentAccessSdkAuditEvent(
                kind: .connectionEstablished,
                remoteFingerprint: "fp",
                remoteName: "Codex",
                query: nil,
                cipherId: nil,
            ))
        }

        let entry = try await XCTUnwrap(store.userData(userId: "1").audit.first)
        XCTAssertEqual(entry.kind, .connectionEstablished)
        XCTAssertEqual(entry.connectionName, "Codex")
        XCTAssertEqual(
            pairingEvents.values,
            [
                .paired(AgentAccessConnection(
                    fingerprint: "fp",
                    name: "Codex",
                    pairedAt: Date(timeIntervalSince1970: 100),
                    lastConnectedAt: Date(timeIntervalSince1970: 200),
                )),
            ],
        )
    }

    /// A rejected connection is audited and published as rejected.
    func test_handleAuditEvent_connectionRejected() async throws {
        await onSdkThread {
            self.subject.handle(auditEvent: AgentAccessSdkAuditEvent(
                kind: .connectionRejected,
                remoteFingerprint: "fp",
                remoteName: nil,
                query: nil,
                cipherId: nil,
            ))
        }

        let audit = try await store.userData(userId: "1").audit
        XCTAssertEqual(audit.map(\.kind), [.connectionRejected])
        XCTAssertEqual(pairingEvents.values, [.rejected])
    }

    /// `verifyFingerprint(code:remoteFingerprint:)` publishes the comparison and returns the answer.
    func test_verifyFingerprint_approved() async throws {
        async let result = onSdkThread { self.subject.verifyFingerprint(code: "a1b2c3", remoteFingerprint: "fp") }
        let published = await waitUntil { !self.pairingEvents.values.isEmpty }
        XCTAssertTrue(published)
        guard case let .verifyFingerprint(verification) = try XCTUnwrap(pairingEvents.values.first) else {
            return XCTFail("Expected a fingerprint verification event")
        }
        XCTAssertEqual(verification.code, "a1b2c3")
        XCTAssertEqual(verification.remoteFingerprint, "fp")

        subject.answerFingerprintVerification(id: verification.id, approved: true)

        let answer = await result
        XCTAssertTrue(answer)
    }

    /// `verifyFingerprint(code:remoteFingerprint:)` returns `false` when the user rejects.
    func test_verifyFingerprint_rejected() async throws {
        async let result = onSdkThread { self.subject.verifyFingerprint(code: "a1b2c3", remoteFingerprint: nil) }
        let published = await waitUntil { !self.pairingEvents.values.isEmpty }
        XCTAssertTrue(published)
        guard case let .verifyFingerprint(verification) = try XCTUnwrap(pairingEvents.values.first) else {
            return XCTFail("Expected a fingerprint verification event")
        }

        subject.answerFingerprintVerification(id: verification.id, approved: false)

        let answer = await result
        XCTAssertFalse(answer)
    }

    // MARK: Tests - Events

    /// `handle(event:)` maps SDK events to the connection status.
    func test_handleEvent_status() {
        subject.handle(event: .connecting)
        subject.handle(event: .listening)
        subject.handle(event: .disconnected)
        subject.handle(event: .reconnected)
        subject.handle(event: .other)

        XCTAssertEqual(statuses.values, [.connecting, .listening, .reconnecting, .listening])
    }

    /// `handle(event:)` publishes SDK errors as a pairing failure.
    func test_handleEvent_error() {
        subject.handle(event: .error(message: "boom"))

        XCTAssertEqual(pairingEvents.values, [.failed(message: "boom")])
    }
}
