import BitwardenKit
import BitwardenKitMocks
import BitwardenSdk
import Networking
import TestHelpers
import XCTest

@testable import BitwardenShared

// MARK: - SSOCookieVendorRequestHandlerTests

class SSOCookieVendorRequestHandlerTests: BitwardenTestCase {
    // MARK: Properties

    var serverCommunicationConfigClientSingleton: MockServerCommunicationConfigClientSingleton!
    var serverCommunicationConfigClient: MockServerCommunicationConfigClient!
    var subject: SSOCookieVendorRequestHandler!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        serverCommunicationConfigClientSingleton = MockServerCommunicationConfigClientSingleton()
        serverCommunicationConfigClient = MockServerCommunicationConfigClient()
        serverCommunicationConfigClientSingleton.clientResult = .success(serverCommunicationConfigClient)

        subject = SSOCookieVendorRequestHandler(
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

    /// `handle(_:)` returns the request unchanged when the singleton closure returns `nil`.
    func test_handle_nilSingleton_returnsUnchanged() async throws {
        subject = SSOCookieVendorRequestHandler(
            serverCommunicationConfigClientSingleton: { nil },
        )
        var request = HTTPRequest(url: URL(string: "https://example.com/api")!)
        let result = try await subject.handle(&request)
        XCTAssertEqual(result.headers, [:])
    }

    /// `handle(_:)` returns the request unchanged when the request URL has no host.
    func test_handle_noHost_returnsUnchanged() async throws {
        var request = HTTPRequest(url: URL(string: "data:text/plain,hello")!)
        let result = try await subject.handle(&request)
        XCTAssertEqual(result.headers, [:])
    }

    /// `handle(_:)` returns the request unchanged when the server config bootstrap is `.direct`.
    func test_handle_directBootstrap_returnsUnchanged() async throws {
        serverCommunicationConfigClient.getConfigResult = .success(ServerCommunicationConfig(bootstrap: .direct))
        var request = HTTPRequest(url: URL(string: "https://example.com/api")!)

        let result = try await subject.handle(&request)

        XCTAssertEqual(result.headers, [:])
        XCTAssertEqual(serverCommunicationConfigClient.getConfigCallsCount, 1)
    }

    /// `handle(_:)` returns the request unchanged when there are no cookies for the hostname.
    func test_handle_ssoCookieVendor_emptyCookies_returnsUnchanged() async throws {
        let ssoConfig = SsoCookieVendorConfig(
            idpLoginUrl: "https://idp.example.com",
            cookieName: "auth",
            cookieDomain: "example.com",
            vaultUrl: "https://example.com",
            cookieValue: nil,
        )
        serverCommunicationConfigClient.getConfigResult = .success(
            ServerCommunicationConfig(bootstrap: .ssoCookieVendor(ssoConfig)),
        )
        serverCommunicationConfigClient.cookiesResult = []
        var request = HTTPRequest(url: URL(string: "https://example.com/api")!)

        let result = try await subject.handle(&request)

        XCTAssertEqual(result.headers, [:])
    }

    /// `handle(_:)` injects cookie headers when the server config is `.ssoCookieVendor`
    /// and cookies are available for the hostname.
    func test_handle_ssoCookieVendor_withCookies_injectsCookieHeader() async throws {
        let ssoConfig = SsoCookieVendorConfig(
            idpLoginUrl: "https://idp.example.com",
            cookieName: "auth",
            cookieDomain: "example.com",
            vaultUrl: "https://example.com",
            cookieValue: nil,
        )
        serverCommunicationConfigClient.getConfigResult = .success(
            ServerCommunicationConfig(bootstrap: .ssoCookieVendor(ssoConfig)),
        )
        serverCommunicationConfigClient.cookiesResult = [AcquiredCookie(name: "auth", value: "token123")]
        var request = HTTPRequest(url: URL(string: "https://example.com/api")!)

        let result = try await subject.handle(&request)

        let cookieHeader = try XCTUnwrap(result.headers["Cookie"])
        XCTAssertTrue(cookieHeader.contains("auth=token123"))
    }

    /// `handle(_:)` uses the resolved hostname from the singleton when looking up the config.
    func test_handle_usesResolvedHostname() async throws {
        serverCommunicationConfigClientSingleton.resolveHostnameResult = "example.com"
        let ssoConfig = SsoCookieVendorConfig(
            idpLoginUrl: "https://idp.example.com",
            cookieName: "auth",
            cookieDomain: "example.com",
            vaultUrl: "https://example.com",
            cookieValue: nil,
        )
        serverCommunicationConfigClient.getConfigResult = .success(
            ServerCommunicationConfig(bootstrap: .ssoCookieVendor(ssoConfig)),
        )
        serverCommunicationConfigClient.cookiesResult = [AcquiredCookie(name: "auth", value: "abc")]
        var request = HTTPRequest(url: URL(string: "https://api.example.com/endpoint")!)

        _ = try await subject.handle(&request)

        XCTAssertEqual(serverCommunicationConfigClientSingleton.resolveHostnameReceivedHostname, "api.example.com")
        XCTAssertEqual(serverCommunicationConfigClient.cookiesReceivedHostname, "example.com")
    }
}
