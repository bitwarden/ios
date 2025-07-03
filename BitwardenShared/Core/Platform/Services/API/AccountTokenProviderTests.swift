import Networking
import TestHelpers
import XCTest

@testable import BitwardenShared

class AccountTokenProviderTests: BitwardenTestCase {
    // MARK: Properties

    var client: MockHTTPClient!
    var subject: DefaultAccountTokenProvider!
    var tokenService: MockTokenService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        client = MockHTTPClient()
        tokenService = MockTokenService()

        subject = DefaultAccountTokenProvider(
            httpService: HTTPService(baseURL: URL(string: "https://example.com")!, client: client),
            tokenService: tokenService
        )
    }

    override func tearDown() {
        super.tearDown()

        client = nil
        subject = nil
        tokenService = nil
    }

    // MARK: Tests

    /// `getToken()` returns the current access token.
    func test_getToken() async throws {
        let token = try await subject.getToken()
        XCTAssertEqual(token, "ACCESS_TOKEN")
    }

    /// `getToken()` throws an error if there's no access token.
    func test_getToken_noAccount() async throws {
        tokenService.accessToken = nil
        tokenService.refreshToken = nil

        await assertAsyncThrows(error: StateServiceError.noActiveAccount) {
            _ = try await subject.getToken()
        }
    }

    /// `refreshToken()` refreshes the access token and updates the token service with the new tokens.
    func test_refreshToken() async throws {
        tokenService.accessToken = "🔑"
        tokenService.refreshToken = "🔒"

        client.result = .httpSuccess(testData: .identityTokenRefresh)

        try await subject.refreshToken()

        let newAccessToken = try await subject.getToken()
        XCTAssertEqual(newAccessToken, "ACCESS_TOKEN")
        XCTAssertEqual(tokenService.accessToken, "ACCESS_TOKEN")
        XCTAssertEqual(tokenService.refreshToken, "REFRESH_TOKEN")

        let refreshTask = await subject.refreshTask
        XCTAssertNil(refreshTask)
    }

    /// `refreshToken()` called concurrently only makes a single request.
    func test_refreshToken_calledConcurrently() async throws {
        tokenService.accessToken = "🔑"
        tokenService.refreshToken = "🔒"

        client.result = .httpSuccess(testData: .identityTokenRefresh)

        async let refreshTask1: Void = subject.refreshToken()
        async let refreshTask2: Void = subject.refreshToken()

        _ = try await (refreshTask1, refreshTask2)

        XCTAssertEqual(client.requests.count, 1)
        XCTAssertEqual(tokenService.accessToken, "ACCESS_TOKEN")
        XCTAssertEqual(tokenService.refreshToken, "REFRESH_TOKEN")

        let refreshTask = await subject.refreshTask
        XCTAssertNil(refreshTask)
    }

    /// `refreshToken()` throws trying to refresh the access token
    /// and gets handled by the delegate before throwing it again.
    func test_refreshToken_handlesErrorInDelegateAndThrows() async throws {
        let delegate = MockAccountTokenProviderDelegate()
        await subject.setDelegate(delegate: delegate)

        tokenService.accessToken = "🔑"
        tokenService.refreshToken = "🔒"

        client.result = .failure(BitwardenTestError.example)

        await assertAsyncThrows(error: BitwardenTestError.example) {
            try await subject.refreshToken()
        }
        XCTAssertTrue(delegate.onRefreshTokenErrorCalled)
    }

    /// `refreshToken()` throws trying to refresh the access token
    /// and gets handled by the delegate before throwing it again.
    func test_refreshToken_throwsWithNoDelegate() async throws {
        tokenService.accessToken = "🔑"
        tokenService.refreshToken = "🔒"

        client.result = .failure(BitwardenTestError.example)

        await assertAsyncThrows(error: BitwardenTestError.example) {
            try await subject.refreshToken()
        }
    }
}
