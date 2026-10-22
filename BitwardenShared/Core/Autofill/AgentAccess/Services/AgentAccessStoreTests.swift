import XCTest

@testable import BitwardenShared

class AgentAccessStoreTests: BitwardenTestCase {
    // MARK: Properties

    var keychainRepository: InMemoryAgentAccessKeychainRepository!
    var subject: DefaultAgentAccessStore!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        keychainRepository = InMemoryAgentAccessKeychainRepository()
        subject = DefaultAgentAccessStore(keychainRepository: keychainRepository)
    }

    override func tearDown() {
        super.tearDown()
        keychainRepository = nil
        subject = nil
    }

    // MARK: Tests

    /// `userData(userId:)` returns empty data when nothing is stored.
    func test_userData_empty() async throws {
        let data = try await subject.userData(userId: "1")

        XCTAssertEqual(data, AgentAccessUserData())
    }

    /// `update(userId:_:)` persists the change and `userData(userId:)` reads it back.
    func test_update_roundTrip() async throws {
        try await subject.update(userId: "1") { data in
            data.identity = Data([1, 2, 3])
            data.listeningEnabled = true
            data.relayURL = "ws://localhost:8080"
        }

        let data = try await subject.userData(userId: "1")
        XCTAssertEqual(data.identity, Data([1, 2, 3]))
        XCTAssertTrue(data.listeningEnabled)
        XCTAssertEqual(data.relayURL, "ws://localhost:8080")
    }

    /// `update(userId:_:)` keeps the data of each user separate.
    func test_update_isolatesUsers() async throws {
        try await subject.update(userId: "1") { $0.listeningEnabled = true }
        try await subject.update(userId: "2") { $0.relayURL = "wss://example.com" }

        let first = try await subject.userData(userId: "1")
        let second = try await subject.userData(userId: "2")
        XCTAssertTrue(first.listeningEnabled)
        XCTAssertNil(first.relayURL)
        XCTAssertFalse(second.listeningEnabled)
        XCTAssertEqual(second.relayURL, "wss://example.com")
    }

    /// Concurrent updates for the same user don't lose changes.
    func test_update_concurrentUpdatesAreSerialized() async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            for index in 0 ..< 20 {
                group.addTask { [subject] in
                    try await subject!.update(userId: "1") { data in
                        data.connections.append(
                            AgentAccessStoredConnection(
                                fingerprint: "fp\(index)",
                                name: nil,
                                cachedAt: 0,
                                lastConnectedAt: 0,
                                transportState: nil,
                            ),
                        )
                    }
                }
            }
            try await group.waitForAll()
        }

        let data = try await subject.userData(userId: "1")
        XCTAssertEqual(data.connections.count, 20)
    }

    /// `appendAudit(_:userId:)` puts the newest entry first.
    func test_appendAudit_newestFirst() async throws {
        let older = makeEntry(kind: .credentialRequested)
        let newer = makeEntry(kind: .credentialApproved)

        try await subject.appendAudit(older, userId: "1")
        try await subject.appendAudit(newer, userId: "1")

        let data = try await subject.userData(userId: "1")
        XCTAssertEqual(data.audit, [newer, older])
    }

    /// `appendAudit(_:userId:)` drops the oldest entries beyond the cap.
    func test_appendAudit_cap() async throws {
        for _ in 0 ..< (AgentAccessConstants.maxAuditEntries + 5) {
            try await subject.appendAudit(makeEntry(kind: .credentialRequested), userId: "1")
        }
        let last = makeEntry(kind: .credentialDenied)
        try await subject.appendAudit(last, userId: "1")

        let data = try await subject.userData(userId: "1")
        XCTAssertEqual(data.audit.count, AgentAccessConstants.maxAuditEntries)
        XCTAssertEqual(data.audit.first, last)
    }

    /// `delete(userId:)` removes the data of the user only.
    func test_delete() async throws {
        try await subject.update(userId: "1") { $0.listeningEnabled = true }
        try await subject.update(userId: "2") { $0.listeningEnabled = true }

        try await subject.delete(userId: "1")

        let first = try await subject.userData(userId: "1")
        let second = try await subject.userData(userId: "2")
        XCTAssertFalse(first.listeningEnabled)
        XCTAssertTrue(second.listeningEnabled)
    }

    // MARK: Private

    private func makeEntry(kind: AgentAccessAuditKind) -> AgentAccessAuditEntry {
        AgentAccessAuditEntry(
            id: UUID(),
            date: Date(timeIntervalSince1970: 1_700_000_000),
            kind: kind,
            connectionFingerprint: "fp",
            connectionName: "Agent",
            query: .domain("example.com"),
            cipherId: nil,
        )
    }
}
