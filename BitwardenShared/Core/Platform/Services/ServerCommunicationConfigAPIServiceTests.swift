import BitwardenKitMocks
import BitwardenSdk
import Combine
import TestHelpers
import XCTest

@testable import BitwardenShared

// MARK: - ServerCommunicationConfigAPIServiceTests

class ServerCommunicationConfigAPIServiceTests: BitwardenTestCase {
    // MARK: Properties

    var appContextHelper: MockAppContextHelper!
    var errorReporter: MockErrorReporter!
    var notificationCenterService: MockNotificationCenterService!
    var subject: DefaultServerCommunicationConfigAPIService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        appContextHelper = MockAppContextHelper()
        errorReporter = MockErrorReporter()
        notificationCenterService = MockNotificationCenterService()
        subject = DefaultServerCommunicationConfigAPIService(
            appContextHelper: appContextHelper,
            errorReporter: errorReporter,
            notificationCenterService: notificationCenterService,
        )
    }

    override func tearDown() {
        super.tearDown()

        appContextHelper = nil
        errorReporter = nil
        notificationCenterService = nil
        subject = nil
    }

    // MARK: Tests

    /// `acquireCookies(vaultUrl:)` emits the vault URL through the publisher and returns cookies
    /// when `cookiesAcquired(cookies:)` is called with a successful result.
    @MainActor
    func test_acquireCookies_success() async throws {
        let vaultURL = "https://example.com"

        let publisher = await subject.acquireCookiesPublisher()
        var emittedVaultURLs = [String?]()
        let cancellable = publisher.sink { emittedVaultURLs.append($0) }
        defer { cancellable.cancel() }

        let acquireTask = Task { await self.subject.acquireCookies(vaultUrl: vaultURL) }

        try await waitForAsync { emittedVaultURLs.contains(vaultURL) }

        await subject.cookiesAcquired(from: .bitwardenSSOCookieVendor)

        let result = await acquireTask.value
        XCTAssertTrue(result?.contains(where: { $0.name == "auth" && $0.value == "token123" }) == true)
        XCTAssertTrue(result?.contains(where: { $0.name == "session" && $0.value == "abc" }) == true)
    }

    /// `acquireCookies(vaultUrl:)` returns `nil` without emitting a vault URL when the main app
    /// is backgrounded.
    @MainActor
    func test_acquireCookies_mainAppBackgrounded_returnsNilWithoutEmitting() async throws {
        notificationCenterService.isInForegroundSubject.send(false)

        let publisher = await subject.acquireCookiesPublisher()
        var emittedVaultURLs = [String?]()
        let cancellable = publisher.sink { emittedVaultURLs.append($0) }
        defer { cancellable.cancel() }

        let result = await subject.acquireCookies(vaultUrl: "https://example.com")

        XCTAssertNil(result)
        // Only the initial nil should have been emitted; no vault URL.
        XCTAssertEqual(emittedVaultURLs, [nil])
    }

    /// `acquireCookies(vaultUrl:)` skips the foreground check and proceeds normally when running
    /// in an app extension context, even if the app is backgrounded.
    @MainActor
    func test_acquireCookies_appExtension_skipsForegroundCheckAndSucceeds() async throws {
        appContextHelper.appContext = .appExtension
        notificationCenterService.isInForegroundSubject.send(false)

        let publisher = await subject.acquireCookiesPublisher()
        var emittedVaultURLs = [String?]()
        let cancellable = publisher.sink { emittedVaultURLs.append($0) }
        defer { cancellable.cancel() }

        let acquireTask = Task { await self.subject.acquireCookies(vaultUrl: "https://example.com") }

        try await waitForAsync { emittedVaultURLs.contains("https://example.com") }

        await subject.cookiesAcquired(from: .bitwardenSSOCookieVendor)

        let result = await acquireTask.value
        XCTAssertTrue(result?.contains(where: { $0.name == "auth" && $0.value == "token123" }) == true)
        XCTAssertTrue(result?.contains(where: { $0.name == "session" && $0.value == "abc" }) == true)
    }

    /// `acquireCookies(vaultUrl:)` returns `nil` immediately when called while another
    /// acquisition is already in flight, leaving the original caller's continuation intact.
    @MainActor
    func test_acquireCookies_concurrentCallDropped() async throws {
        let vaultURL = "https://example.com"

        let publisher = await subject.acquireCookiesPublisher()
        var emittedVaultURLs = [String?]()
        let cancellable = publisher.sink { emittedVaultURLs.append($0) }
        defer { cancellable.cancel() }

        let firstTask = Task { await self.subject.acquireCookies(vaultUrl: vaultURL) }

        // Wait until the first call has registered its continuation.
        try await waitForAsync { emittedVaultURLs.contains(vaultURL) }

        // A second concurrent call should be dropped and not emit to the publisher.
        let secondResult = await subject.acquireCookies(vaultUrl: "https://other.com")
        XCTAssertNil(secondResult)
        XCTAssertFalse(emittedVaultURLs.contains("https://other.com"))

        // The original continuation should still be satisfied normally.
        await subject.cookiesAcquired(from: .bitwardenSSOCookieVendor)

        let result = await firstTask.value
        XCTAssertTrue(result?.contains(where: { $0.name == "auth" && $0.value == "token123" }) == true)
        XCTAssertTrue(result?.contains(where: { $0.name == "session" && $0.value == "abc" }) == true)
    }

    /// `acquireCookies(vaultUrl:)` succeeds on a subsequent call once the previous
    /// acquisition has completed and its continuation has been cleared.
    @MainActor
    func test_acquireCookies_succeedsAfterPreviousCompletes() async throws {
        let vaultURL = "https://example.com"

        let publisher = await subject.acquireCookiesPublisher()
        var emittedVaultURLs = [String?]()
        let cancellable = publisher.sink { emittedVaultURLs.append($0) }
        defer { cancellable.cancel() }

        // Complete the first acquisition.
        let firstTask = Task { await self.subject.acquireCookies(vaultUrl: vaultURL) }
        try await waitForAsync { emittedVaultURLs.contains(vaultURL) }
        await subject.cookiesAcquired(from: .bitwardenSSOCookieVendor)
        _ = await firstTask.value

        // A second acquisition should be accepted and resolved normally.
        let secondTask = Task { await self.subject.acquireCookies(vaultUrl: vaultURL) }
        try await waitForAsync { emittedVaultURLs.count(where: { $0 == vaultURL }) == 2 }

        // The original continuation should still be satisfied normally.
        await subject.cookiesAcquired(from: .bitwardenSSOCookieVendor)

        let result = await secondTask.value
        XCTAssertTrue(result?.contains(where: { $0.name == "auth" && $0.value == "token123" }) == true)
        XCTAssertTrue(result?.contains(where: { $0.name == "session" && $0.value == "abc" }) == true)
    }

    /// `acquireCookiesPublisher()` returns a publisher that starts with `nil`.
    func test_acquireCookiesPublisher_initialValueIsNil() async {
        let publisher = await subject.acquireCookiesPublisher()

        var receivedValues = [String?]()
        let cancellable = publisher.sink { receivedValues.append($0) }
        defer { cancellable.cancel() }

        XCTAssertEqual(receivedValues, [nil])
    }

    // MARK: Tests - cookiesAcquired(from:)

    /// `cookiesAcquired(from:)` parses cookies from the callback URL query parameters and delivers
    /// them to the pending continuation.
    @MainActor
    func test_cookiesAcquiredFrom_parsesCookies() async throws {
        let publisher = await subject.acquireCookiesPublisher()
        var emittedVaultURLs = [String?]()
        let cancellable = publisher.sink { emittedVaultURLs.append($0) }
        defer { cancellable.cancel() }

        let acquireTask = Task { await self.subject.acquireCookies(vaultUrl: "https://example.com") }
        try await waitForAsync { emittedVaultURLs.contains("https://example.com") }

        await subject.cookiesAcquired(from: .bitwardenSSOCookieVendor)

        let result = await acquireTask.value
        let cookies = try XCTUnwrap(result)
        XCTAssertEqual(cookies.count, 2)
        XCTAssertTrue(cookies.contains(where: { $0.name == "auth" && $0.value == "token123" }))
        XCTAssertTrue(cookies.contains(where: { $0.name == "session" && $0.value == "abc" }))
    }

    /// `cookiesAcquired(from:)` excludes the `"d"` query parameter from the delivered cookies.
    @MainActor
    func test_cookiesAcquiredFrom_excludesDParam() async throws {
        let publisher = await subject.acquireCookiesPublisher()
        var emittedVaultURLs = [String?]()
        let cancellable = publisher.sink { emittedVaultURLs.append($0) }
        defer { cancellable.cancel() }

        let acquireTask = Task { await self.subject.acquireCookies(vaultUrl: "https://example.com") }
        try await waitForAsync { emittedVaultURLs.contains("https://example.com") }

        await subject.cookiesAcquired(from: .bitwardenSSOCookieVendorDParam)

        let result = await acquireTask.value
        let cookies = try XCTUnwrap(result)
        XCTAssertFalse(cookies.contains(where: { $0.name == "d" }))
        XCTAssertTrue(cookies.contains(where: { $0.name == "auth" && $0.value == "myToken" }))
    }

    /// `cookiesAcquired(from:)` with a URL that has no query parameters resumes the pending
    /// continuation with nil cookies.
    @MainActor
    func test_cookiesAcquiredFrom_noQueryParameters_deliversNilCookies() async throws {
        let publisher = await subject.acquireCookiesPublisher()
        var emittedVaultURLs = [String?]()
        let cancellable = publisher.sink { emittedVaultURLs.append($0) }
        defer { cancellable.cancel() }

        let acquireTask = Task { await self.subject.acquireCookies(vaultUrl: "https://example.com") }
        try await waitForAsync { emittedVaultURLs.contains("https://example.com") }

        await subject.cookiesAcquired(from: .bitwardenSSOCookieVendorNoCookies)

        let result = await acquireTask.value
        XCTAssertNil(result)
    }

    /// `cookiesAcquired(from:)` with a nil URL (e.g. web auth session cancelled) resumes the
    /// pending continuation with nil cookies.
    @MainActor
    func test_cookiesAcquiredFrom_nilURL_resumesWithNilCookies() async throws {
        let publisher = await subject.acquireCookiesPublisher()
        var emittedVaultURLs = [String?]()
        let cancellable = publisher.sink { emittedVaultURLs.append($0) }
        defer { cancellable.cancel() }

        let acquireTask = Task { await self.subject.acquireCookies(vaultUrl: "https://example.com") }
        try await waitForAsync { emittedVaultURLs.contains("https://example.com") }

        // nil signals cancellation; the continuation is resumed with nil.
        await subject.cookiesAcquired(from: nil)

        let result = await acquireTask.value
        XCTAssertNil(result)
    }

    /// `cookiesAcquired(from:)` with a URL that does not match the SSO cookie vendor scheme
    /// resumes the pending continuation with nil cookies.
    @MainActor
    func test_cookiesAcquiredFrom_nonMatchingURL_resumesWithNilCookies() async throws {
        let publisher = await subject.acquireCookiesPublisher()
        var emittedVaultURLs = [String?]()
        let cancellable = publisher.sink { emittedVaultURLs.append($0) }
        defer { cancellable.cancel() }

        let acquireTask = Task { await self.subject.acquireCookies(vaultUrl: "https://example.com") }
        try await waitForAsync { emittedVaultURLs.contains("https://example.com") }

        // A URL with a different path does not match the scheme; the continuation is resumed with nil.
        await subject.cookiesAcquired(from: URL(string: "bitwarden://other-path?cookie=value")!)

        let result = await acquireTask.value
        XCTAssertNil(result)
    }
}
