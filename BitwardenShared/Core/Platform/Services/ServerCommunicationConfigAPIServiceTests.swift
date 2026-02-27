import BitwardenKitMocks
import BitwardenSdk
import Combine
import TestHelpers
import XCTest

@testable import BitwardenShared

// MARK: - ServerCommunicationConfigAPIServiceTests

class ServerCommunicationConfigAPIServiceTests: BitwardenTestCase {
    // MARK: Properties

    var errorReporter: MockErrorReporter!
    var subject: DefaultServerCommunicationConfigAPIService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        errorReporter = MockErrorReporter()
        subject = DefaultServerCommunicationConfigAPIService(errorReporter: errorReporter)
    }

    override func tearDown() {
        super.tearDown()

        errorReporter = nil
        subject = nil
    }

    // MARK: Tests

    /// `acquireCookies(hostname:)` emits the hostname through the publisher and returns cookies
    /// when `cookiesAcquired(cookies:)` is called with a successful result.
    @MainActor
    func test_acquireCookies_success() async throws {
        let hostname = "example.com"
        let cookies = [AcquiredCookie(name: "session", value: "token123")]

        let publisher = await subject.acquireCookiesPublisher()
        var emittedHostnames = [String?]()
        let cancellable = publisher.sink { emittedHostnames.append($0) }
        defer { cancellable.cancel() }

        let acquireTask = Task { await self.subject.acquireCookies(hostname: hostname) }

        try await waitForAsync { emittedHostnames.contains(hostname) }

        await subject.cookiesAcquired(cookies: .success(cookies))

        let result = await acquireTask.value
        XCTAssertEqual(result?.first?.name, "session")
        XCTAssertEqual(result?.first?.value, "token123")
    }

    /// `acquireCookies(hostname:)` returns `nil` and logs the error when `cookiesAcquired`
    /// is called with a failure result.
    @MainActor
    func test_acquireCookies_error() async throws {
        let hostname = "example.com"

        let publisher = await subject.acquireCookiesPublisher()
        var emittedHostnames = [String?]()
        let cancellable = publisher.sink { emittedHostnames.append($0) }
        defer { cancellable.cancel() }

        let acquireTask = Task { await self.subject.acquireCookies(hostname: hostname) }

        try await waitForAsync { emittedHostnames.contains(hostname) }

        await subject.cookiesAcquired(cookies: .failure(BitwardenTestError.example))

        let result = await acquireTask.value
        XCTAssertNil(result)
        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
    }

    /// `acquireCookiesPublisher()` returns a publisher that starts with `nil`.
    func test_acquireCookiesPublisher_initialValueIsNil() async {
        let publisher = await subject.acquireCookiesPublisher()

        var receivedValues = [String?]()
        let cancellable = publisher.sink { receivedValues.append($0) }
        defer { cancellable.cancel() }

        XCTAssertEqual(receivedValues, [nil])
    }

    /// `acquireCookies(hostname:)` returns `nil` immediately when called while another
    /// acquisition is already in flight, leaving the original caller's continuation intact.
    @MainActor
    func test_acquireCookies_concurrentCallDropped() async throws {
        let hostname = "example.com"
        let cookies = [AcquiredCookie(name: "session", value: "token123")]

        let publisher = await subject.acquireCookiesPublisher()
        var emittedHostnames = [String?]()
        let cancellable = publisher.sink { emittedHostnames.append($0) }
        defer { cancellable.cancel() }

        let firstTask = Task { await self.subject.acquireCookies(hostname: hostname) }

        // Wait until the first call has registered its continuation.
        try await waitForAsync { emittedHostnames.contains(hostname) }

        // A second concurrent call should be dropped and not emit to the publisher.
        let secondResult = await subject.acquireCookies(hostname: "other.com")
        XCTAssertNil(secondResult)
        XCTAssertFalse(emittedHostnames.contains("other.com"))

        // The original continuation should still be satisfied normally.
        await subject.cookiesAcquired(cookies: .success(cookies))
        let firstResult = await firstTask.value
        XCTAssertEqual(firstResult?.first?.name, "session")
        XCTAssertEqual(firstResult?.first?.value, "token123")
    }

    /// `acquireCookies(hostname:)` succeeds on a subsequent call once the previous
    /// acquisition has completed and its continuation has been cleared.
    @MainActor
    func test_acquireCookies_succeedsAfterPreviousCompletes() async throws {
        let hostname = "example.com"
        let cookies = [AcquiredCookie(name: "session", value: "token123")]

        let publisher = await subject.acquireCookiesPublisher()
        var emittedHostnames = [String?]()
        let cancellable = publisher.sink { emittedHostnames.append($0) }
        defer { cancellable.cancel() }

        // Complete the first acquisition.
        let firstTask = Task { await self.subject.acquireCookies(hostname: hostname) }
        try await waitForAsync { emittedHostnames.contains(hostname) }
        await subject.cookiesAcquired(cookies: .success(cookies))
        _ = await firstTask.value

        // A second acquisition should be accepted and resolved normally.
        let secondTask = Task { await self.subject.acquireCookies(hostname: hostname) }
        try await waitForAsync { emittedHostnames.count(where: {$0 == hostname}) == 2 }
        await subject.cookiesAcquired(cookies: .success(cookies))
        let secondResult = await secondTask.value
        XCTAssertEqual(secondResult?.first?.name, "session")
        XCTAssertEqual(secondResult?.first?.value, "token123")
    }

    /// `cookiesAcquired(cookies:)` with no pending continuation does not crash.
    func test_cookiesAcquired_noPendingContinuation_doesNotCrash() async {
        await subject.cookiesAcquired(cookies: .success([AcquiredCookie(name: "n", value: "v")]))
    }
}
