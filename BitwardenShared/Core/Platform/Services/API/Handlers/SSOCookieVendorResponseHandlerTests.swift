import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import BitwardenSdk
import Networking
import TestHelpers
import XCTest

@testable import BitwardenShared

// MARK: - SSOCookieVendorResponseHandlerTests

class SSOCookieVendorResponseHandlerTests: BitwardenTestCase {
    // MARK: Properties

    var serverCommunicationConfigClientSingleton: MockServerCommunicationConfigClientSingleton!
    var serverCommunicationConfigClient: MockServerCommunicationConfigClient!
    var subject: SSOCookieVendorResponseHandler!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        serverCommunicationConfigClientSingleton = MockServerCommunicationConfigClientSingleton()
        serverCommunicationConfigClient = MockServerCommunicationConfigClient()
        serverCommunicationConfigClientSingleton.clientResult = .success(serverCommunicationConfigClient)

        subject = SSOCookieVendorResponseHandler(
            serverCommunicationConfigClientSingleton: { [weak self] in self?.serverCommunicationConfigClientSingleton },
        )
    }

    override func tearDown() {
        super.tearDown()

        serverCommunicationConfigClientSingleton = nil
        serverCommunicationConfigClient = nil
        subject = nil
    }

    // MARK: Tests

    /// `handle(_:for:retryWith:)` returns the response unchanged for non-302 status codes.
    func test_handle_nonRedirect_returnsUnchanged() async throws {
        for statusCode in [200, 301, 400, 500] {
            var response = HTTPResponse.success(statusCode: statusCode)
            let request = HTTPRequest(url: URL(string: "https://example.com/api")!)

            let result = try await subject.handle(&response, for: request, retryWith: nil)

            XCTAssertEqual(result.statusCode, statusCode)
            XCTAssertEqual(serverCommunicationConfigClient.acquireCookieCallsCount, 0)
        }
    }

    /// `handle(_:for:retryWith:)` returns the response unchanged when the singleton closure returns
    /// `nil` and no `retryWith` closure is provided.
    func test_handle_302_nilSingleton_nilRetryWith_returnsResponse() async throws {
        subject = SSOCookieVendorResponseHandler(
            serverCommunicationConfigClientSingleton: { nil },
        )
        var response = HTTPResponse.failure(
            statusCode: 302,
            headers: ["Location": "https://redirected.example.com"],
        )
        let request = HTTPRequest(url: URL(string: "https://example.com/api")!)

        let result = try await subject.handle(&response, for: request, retryWith: nil)

        XCTAssertEqual(result.statusCode, 302)
    }

    /// `handle(_:for:retryWith:)` follows the redirect manually when the singleton closure returns
    /// `nil` but a `retryWith` closure is provided.
    func test_handle_302_nilSingleton_withRetryWith_followsRedirect() async throws {
        subject = SSOCookieVendorResponseHandler(
            serverCommunicationConfigClientSingleton: { nil },
        )
        var response = HTTPResponse.failure(
            statusCode: 302,
            headers: ["Location": "https://redirected.example.com"],
        )
        let request = HTTPRequest(url: URL(string: "https://example.com/api")!)

        var retryWithReceivedRequest: HTTPRequest?
        let redirectedResponse = HTTPResponse.success(statusCode: 200)
        let result = try await subject.handle(&response, for: request) { req in
            retryWithReceivedRequest = req
            return redirectedResponse
        }

        XCTAssertEqual(retryWithReceivedRequest?.url, URL(string: "https://redirected.example.com")!)
        XCTAssertEqual(result.statusCode, 200)
    }

    /// `handle(_:for:retryWith:)` follows the redirect manually when the host does not need bootstrap.
    func test_handle_302_noBootstrapNeeded_followsRedirect() async throws {
        serverCommunicationConfigClient.needsBootstrapResult = false
        var response = HTTPResponse.failure(
            statusCode: 302,
            headers: ["Location": "https://redirected.example.com"],
        )
        let request = HTTPRequest(url: URL(string: "https://example.com/api")!)

        var retryWithReceivedRequest: HTTPRequest?
        let redirectedResponse = HTTPResponse.success(statusCode: 200)
        let result = try await subject.handle(&response, for: request) { req in
            retryWithReceivedRequest = req
            return redirectedResponse
        }

        XCTAssertEqual(retryWithReceivedRequest?.url, URL(string: "https://redirected.example.com")!)
        XCTAssertEqual(result.statusCode, 200)
        XCTAssertEqual(serverCommunicationConfigClient.acquireCookieCallsCount, 0)
    }

    /// `handle(_:for:retryWith:)` calls `acquireCookie` and throws a "try again" `ServerError`
    /// when the host needs bootstrap.
    func test_handle_302_needsBootstrap_callsAcquireCookieAndThrows() async throws {
        serverCommunicationConfigClient.needsBootstrapResult = true
        var response = HTTPResponse.failure(statusCode: 302)
        let request = HTTPRequest(url: URL(string: "https://example.com/api")!)

        await assertAsyncThrows {
            _ = try await self.subject.handle(&response, for: request, retryWith: nil)
        }

        XCTAssertEqual(serverCommunicationConfigClient.acquireCookieCallsCount, 1)
        XCTAssertEqual(serverCommunicationConfigClient.acquireCookieReceivedHostname, "example.com")
    }

    /// `handle(_:for:retryWith:)` calls `acquireCookie`, silently ignores a `Cancelled` error,
    /// and still throws a "try again" `ServerError`.
    func test_handle_302_needsBootstrap_acquireCookieCancelled_throwsTryAgain() async throws {
        serverCommunicationConfigClient.needsBootstrapResult = true
        serverCommunicationConfigClient.acquireCookieError = BitwardenSdk.BitwardenError.AcquireCookie(
            .Cancelled(message: "user cancelled"),
        )
        var response = HTTPResponse.failure(statusCode: 302)
        let request = HTTPRequest(url: URL(string: "https://example.com/api")!)

        var thrownError: Error?
        do {
            _ = try await subject.handle(&response, for: request, retryWith: nil)
        } catch {
            thrownError = error
        }

        XCTAssertEqual(serverCommunicationConfigClient.acquireCookieCallsCount, 1)
        guard let serverError = thrownError as? ServerError,
              case let .error(errorResponse) = serverError else {
            XCTFail("Expected ServerError.error, got \(String(describing: thrownError))")
            return
        }
        XCTAssertEqual(
            errorResponse.message,
            Localizations.yourRequestWasInterruptedBecauseTheAppNeededToReAuthenticatePleaseTryAgain,
        )
    }

    /// `handle(_:for:retryWith:)` throws the underlying error when `acquireCookie` fails with
    /// a non-`Cancelled` error.
    func test_handle_302_needsBootstrap_acquireCookieNonCancelledError_throwsError() async throws {
        serverCommunicationConfigClient.needsBootstrapResult = true
        serverCommunicationConfigClient.acquireCookieError = BitwardenTestError.example
        var response = HTTPResponse.failure(statusCode: 302)
        let request = HTTPRequest(url: URL(string: "https://example.com/api")!)

        await assertAsyncThrows(error: BitwardenTestError.example) {
            _ = try await self.subject.handle(&response, for: request, retryWith: nil)
        }
    }

    /// `handle(_:for:retryWith:)` uses the resolved hostname from the singleton.
    func test_handle_302_usesResolvedHostname() async throws {
        serverCommunicationConfigClientSingleton.resolveHostnameResult = "example.com"
        serverCommunicationConfigClient.needsBootstrapResult = true
        var response = HTTPResponse.failure(statusCode: 302)
        let request = HTTPRequest(url: URL(string: "https://api.example.com/endpoint")!)

        do {
            _ = try await subject.handle(&response, for: request, retryWith: nil)
        } catch {}

        XCTAssertEqual(serverCommunicationConfigClientSingleton.resolveHostnameReceivedHostname, "api.example.com")
        XCTAssertEqual(serverCommunicationConfigClient.needsBootstrapReceivedHostname, "example.com")
    }

    /// `handle(_:for:retryWith:)` returns the 302 response when there is no `Location` header
    /// and no need to bootstrap.
    func test_handle_302_noLocationHeader_noBootstrap_returnsResponse() async throws {
        serverCommunicationConfigClient.needsBootstrapResult = false
        var response = HTTPResponse.failure(statusCode: 302)
        let request = HTTPRequest(url: URL(string: "https://example.com/api")!)

        let result = try await subject.handle(&response, for: request, retryWith: nil)

        XCTAssertEqual(result.statusCode, 302)
    }
}
