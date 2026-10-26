import BitwardenKit
import BitwardenKitMocks
import XCTest

@testable import BitwardenShared

class AgentAccessApprovalCenterTests: BitwardenTestCase {
    // MARK: Properties

    var subject: AgentAccessApprovalCenter!
    var timeProvider: MockTimeProvider!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        timeProvider = MockTimeProvider(.mockTime(Date(timeIntervalSince1970: 1_700_000_000)))
        subject = AgentAccessApprovalCenter(timeProvider: timeProvider)
    }

    override func tearDown() {
        super.tearDown()
        subject = nil
        timeProvider = nil
    }

    // MARK: Tests

    /// `requestApproval(_:)` blocks until the request is approved and returns the credential.
    func test_requestApproval_approved() async throws {
        let request = makeRequest(id: "r1", window: 30)
        let credential = AgentAccessSdkCredential(username: "u", password: "p", credentialId: "c", domain: nil)

        async let outcome = onBlockingThread { self.subject.requestApproval(request) }
        try await waitForPending(count: 1)
        XCTAssertEqual(subject.pendingRequest(id: "r1"), request)
        XCTAssertNotNil(subject.resolve(id: "r1", outcome: .approved(credential)))

        let result = await outcome
        XCTAssertEqual(result, .approved(credential))
        XCTAssertNil(subject.pendingRequest(id: "r1"))
    }

    /// `requestApproval(_:)` returns `.denied` when the request is denied.
    func test_requestApproval_denied() async throws {
        let request = makeRequest(id: "r1", window: 30)

        async let outcome = onBlockingThread { self.subject.requestApproval(request) }
        try await waitForPending(count: 1)
        subject.resolve(id: "r1", outcome: .denied)

        let result = await outcome
        XCTAssertEqual(result, .denied)
    }

    /// `requestApproval(_:)` returns `.expired` and removes the request when the window passes.
    func test_requestApproval_expires() async {
        let request = makeRequest(id: "r1", window: 0.2)

        let result = await onBlockingThread { self.subject.requestApproval(request) }

        XCTAssertEqual(result, .expired)
        XCTAssertNil(subject.pendingRequest(id: "r1"))
    }

    /// `requestApproval(_:)` returns `.expired` right away when the window has already passed.
    func test_requestApproval_alreadyExpired() async {
        let request = makeRequest(id: "r1", window: -1)

        let result = await onBlockingThread { self.subject.requestApproval(request) }

        XCTAssertEqual(result, .expired)
    }

    /// `resolve(id:outcome:)` returns `nil` for an unknown request.
    func test_resolve_unknown() {
        XCTAssertNil(subject.resolve(id: "missing", outcome: .denied))
    }

    /// `denyAll(connectionFingerprint:)` denies only the requests of that connection.
    func test_denyAll_connection() async throws {
        let first = makeRequest(id: "r1", fingerprint: "a", window: 30)
        let second = makeRequest(id: "r2", fingerprint: "b", window: 30)

        async let firstOutcome = onBlockingThread { self.subject.requestApproval(first) }
        async let secondOutcome = onBlockingThread { self.subject.requestApproval(second) }
        try await waitForPending(count: 2)

        subject.denyAll(connectionFingerprint: "a")
        let firstResult = await firstOutcome
        XCTAssertEqual(firstResult, .denied)
        XCTAssertNotNil(subject.pendingRequest(id: "r2"))

        subject.denyAll()
        let secondResult = await secondOutcome
        XCTAssertEqual(secondResult, .denied)
        XCTAssertTrue(subject.pendingRequests().isEmpty)
    }

    /// The pending requests are published oldest first.
    func test_pendingRequestsPublisher() async throws {
        let first = makeRequest(id: "r1", window: 30)
        let second = makeRequest(id: "r2", window: 30)

        async let firstOutcome = onBlockingThread { self.subject.requestApproval(first) }
        try await waitForPending(count: 1)
        async let secondOutcome = onBlockingThread { self.subject.requestApproval(second) }
        try await waitForPending(count: 2)

        var iterator = subject.pendingRequestsPublisher().values.makeAsyncIterator()
        let published = await iterator.next()
        XCTAssertEqual(published?.map(\.id), ["r1", "r2"])

        subject.denyAll()
        _ = await (firstOutcome, secondOutcome)
    }

    /// A rule matches an identical query from the same connection until it expires.
    func test_rules_matchAndExpire() {
        subject.addRule(
            connectionFingerprint: "a",
            connectionName: "Agent",
            query: .domain("Example.com"),
            cipherId: "c",
            duration: 60,
        )

        XCTAssertEqual(
            subject.matchingRule(connectionFingerprint: "a", query: .domain("example.com"))?.cipherId,
            "c",
        )
        XCTAssertNil(subject.matchingRule(connectionFingerprint: "b", query: .domain("example.com")))
        XCTAssertNil(subject.matchingRule(connectionFingerprint: "a", query: .domain("other.com")))
        XCTAssertNil(subject.matchingRule(connectionFingerprint: "a", query: .search("example.com")))

        timeProvider.timeConfig = .mockTime(Date(timeIntervalSince1970: 1_700_000_061))

        XCTAssertNil(subject.matchingRule(connectionFingerprint: "a", query: .domain("example.com")))
        XCTAssertTrue(subject.autoApproveRules().isEmpty)
    }

    /// `addRule` replaces the rule for the same connection and query.
    func test_rules_replace() {
        subject.addRule(connectionFingerprint: "a", connectionName: "A", query: .id("1"), cipherId: "c1", duration: 60)
        subject.addRule(connectionFingerprint: "a", connectionName: "A", query: .id("1"), cipherId: "c2", duration: 60)

        XCTAssertEqual(subject.autoApproveRules().map(\.cipherId), ["c2"])
    }

    /// `removeRule(id:)` and `removeRules(connectionFingerprint:)` remove rules.
    func test_rules_remove() throws {
        subject.addRule(connectionFingerprint: "a", connectionName: "A", query: .id("1"), cipherId: "c1", duration: 60)
        subject.addRule(connectionFingerprint: "b", connectionName: "B", query: .id("1"), cipherId: "c2", duration: 60)
        subject.addRule(connectionFingerprint: "b", connectionName: "B", query: .id("2"), cipherId: "c3", duration: 60)

        subject.removeRules(connectionFingerprint: "b")
        let remaining = subject.autoApproveRules()
        XCTAssertEqual(remaining.map(\.cipherId), ["c1"])

        try subject.removeRule(id: XCTUnwrap(remaining.first).id)
        XCTAssertTrue(subject.autoApproveRules().isEmpty)
    }

    // MARK: Private

    private func makeRequest(
        id: String,
        fingerprint: String = "a",
        window: TimeInterval,
    ) -> AgentAccessApprovalRequest {
        let now = timeProvider.presentTime
        return AgentAccessApprovalRequest(
            id: id,
            userId: "1",
            connectionFingerprint: fingerprint,
            connectionName: "Agent",
            query: .domain("example.com"),
            receivedAt: now,
            expiresAt: now.addingTimeInterval(window),
        )
    }

    private func onBlockingThread<T: Sendable>(_ work: @escaping @Sendable () -> T) async -> T {
        await withCheckedContinuation { continuation in
            DispatchQueue.global().async {
                continuation.resume(returning: work())
            }
        }
    }

    private func waitForPending(count: Int) async throws {
        for _ in 0 ..< 200 {
            if subject.pendingRequests().count == count { return }
            try await Task.sleep(nanoseconds: 10_000_000)
        }
        XCTFail("Timed out waiting for \(count) pending requests")
    }
}
