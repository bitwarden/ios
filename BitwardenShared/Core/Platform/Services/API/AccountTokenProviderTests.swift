import BitwardenKitMocks
import Networking
import TestHelpers
import XCTest

@testable import BitwardenShared

class AccountTokenProviderTests: BitwardenTestCase {
    // MARK: Properties

    var client: MockHTTPClient!
    var subject: DefaultAccountTokenProvider!
    var timeProvider: MockTimeProvider!
    var tokenService: MockTokenService!

    let expirationDateExpired = Date(year: 2025, month: 10, day: 1, hour: 23, minute: 59, second: 0)
    let expirationDateExpiringSoon = Date(year: 2025, month: 10, day: 2, hour: 0, minute: 2, second: 0)
    let expirationDateUnexpired = Date(year: 2025, month: 10, day: 2, hour: 0, minute: 6, second: 0)

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        client = MockHTTPClient()
        timeProvider = MockTimeProvider(.mockTime(Date(year: 2025, month: 10, day: 2)))
        tokenService = MockTokenService()

        subject = DefaultAccountTokenProvider(
            httpService: HTTPService(baseURL: URL(string: "https://example.com")!, client: client),
            timeProvider: timeProvider,
            tokenService: tokenService,
        )
    }

    override func tearDown() {
        super.tearDown()

        client = nil
        subject = nil
        timeProvider = nil
        tokenService = nil
    }

    // MARK: Tests

    /// `getToken()` returns the current access token if fetching the expiration date returns an error.
    func test_getToken_tokenError() async throws {
        tokenService.accessToken = "ACCESS_TOKEN"
        tokenService.accessTokenExpirationDateResult = .failure(BitwardenTestError.example)

        let token = try await subject.getToken()
        XCTAssertEqual(token, "ACCESS_TOKEN")
    }

    /// `getToken()` returns a refreshed access token if the current one is expired.
    func test_getToken_tokenExpired() async throws {
        client.result = .httpSuccess(testData: .identityTokenRefresh)
        tokenService.accessToken = "EXPIRED"
        tokenService.accessTokenExpirationDateResult = .success(expirationDateExpired)

        let token = try await subject.getToken()
        XCTAssertEqual(token, "ACCESS_TOKEN")
    }

    /// `getToken()` returns a refreshed access token if the current one is expiring soon.
    func test_getToken_tokenExpiringSoon() async throws {
        client.result = .httpSuccess(testData: .identityTokenRefresh)
        tokenService.accessToken = "EXPIRING_SOON"
        tokenService.accessTokenExpirationDateResult = .success(expirationDateExpiringSoon)

        let token = try await subject.getToken()
        XCTAssertEqual(token, "ACCESS_TOKEN")
    }

    /// `getToken()` returns the current access token if it is unexpired.
    func test_getToken_tokenUnexpired() async throws {
        tokenService.accessToken = "ACCESS_TOKEN"
        tokenService.accessTokenExpirationDateResult = .success(expirationDateUnexpired)

        let token = try await subject.getToken()
        XCTAssertEqual(token, "ACCESS_TOKEN")
    }

    /// `getToken()` returns the current access token if the expiration date doesn't yet exist.
    func test_getToken_tokenNil() async throws {
        tokenService.accessToken = "ACCESS_TOKEN"
        tokenService.accessTokenExpirationDateResult = .success(nil)

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

        let newAccessToken = try await subject.refreshToken()

        XCTAssertEqual(newAccessToken, "ACCESS_TOKEN")
        XCTAssertEqual(tokenService.accessToken, "ACCESS_TOKEN")
        XCTAssertEqual(tokenService.refreshToken, "REFRESH_TOKEN")
        XCTAssertEqual(tokenService.expirationDate, Date(year: 2025, month: 10, day: 2, hour: 1, minute: 0, second: 0))

        let refreshTask = await subject.refreshTask
        XCTAssertNil(refreshTask)
    }

    /// `refreshToken()` called concurrently only makes a single request.
    func test_refreshToken_calledConcurrently() async throws {
        tokenService.accessToken = "🔑"
        tokenService.refreshToken = "🔒"

        client.result = .httpSuccess(testData: .identityTokenRefresh)

        async let refreshTask1: String = subject.refreshToken()
        async let refreshTask2: String = subject.refreshToken()

        _ = try await (refreshTask1, refreshTask2)

        XCTAssertEqual(client.requests.count, 1)
        XCTAssertEqual(tokenService.accessToken, "ACCESS_TOKEN")
        XCTAssertEqual(tokenService.refreshToken, "REFRESH_TOKEN")
        XCTAssertEqual(tokenService.expirationDate, Date(year: 2025, month: 10, day: 2, hour: 1, minute: 0, second: 0))

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
            _ = try await subject.refreshToken()
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
            _ = try await subject.refreshToken()
        }
    }
}
