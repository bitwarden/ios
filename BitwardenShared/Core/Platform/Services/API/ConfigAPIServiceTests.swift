import BitwardenKit
import BitwardenKitMocks
import TestHelpers
import XCTest

@testable import BitwardenShared
@testable import BitwardenSharedMocks

@MainActor
class ConfigAPIServiceTests: BitwardenTestCase {
    // MARK: Properties

    var accountTokenProvider: MockAccountTokenProvider!
    var activeAccountStateProvider: MockActiveAccountStateProvider!
    var client: MockHTTPClient!
    var stateService: MockStateService!
    var subject: ConfigAPIService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        accountTokenProvider = MockAccountTokenProvider()
        accountTokenProvider.getTokenReturnValue = "ACCESS_TOKEN"
        activeAccountStateProvider = MockActiveAccountStateProvider()
        client = MockHTTPClient()
        stateService = MockStateService()
        subject = APIService(
            accountTokenProvider: accountTokenProvider,
            activeAccountStateProvider: activeAccountStateProvider,
            client: client,
            stateService: stateService,
        )
    }

    override func tearDown() async throws {
        try await super.tearDown()

        accountTokenProvider = nil
        activeAccountStateProvider = nil
        client = nil
        stateService = nil
        subject = nil
    }

    // MARK: Tests

    /// `getConfig()` performs the config request authenticated.
    func test_getConfig() async throws {
        let account = Account.fixture()
        stateService.activeAccount = account
        stateService.isAuthenticated[account.profile.userId] = true
        client.result = .httpSuccess(testData: .validServerConfig)

        _ = try await subject.getConfig()

        let request = try XCTUnwrap(client.requests.last)
        XCTAssertEqual(request.method, .get)
        XCTAssertEqual(request.url.absoluteString, "https://example.com/api/config")
        XCTAssertNil(request.body)
        XCTAssertNotNil(request.headers["Authorization"])
    }

    /// `getConfig()` performs the config request unauthenticated.
    func test_getConfig_unauthenticated() async throws {
        let account = Account.fixture()
        stateService.activeAccount = account
        stateService.isAuthenticated[account.profile.userId] = false
        client.result = .httpSuccess(testData: .validServerConfig)

        _ = try await subject.getConfig()

        let request = try XCTUnwrap(client.requests.last)
        XCTAssertEqual(request.method, .get)
        XCTAssertEqual(request.url.absoluteString, "https://example.com/api/config")
        XCTAssertNil(request.body)
        XCTAssertNil(request.headers["Authorization"])
    }

    /// `getConfig()` performs the config request unauthenticated because there is no active account.
    func test_getConfig_unauthenticatedNoAccount() async throws {
        client.result = .httpSuccess(testData: .validServerConfig)

        _ = try await subject.getConfig()

        let request = try XCTUnwrap(client.requests.last)
        XCTAssertEqual(request.method, .get)
        XCTAssertEqual(request.url.absoluteString, "https://example.com/api/config")
        XCTAssertNil(request.body)
        XCTAssertNil(request.headers["Authorization"])
    }

    /// `getConfig()` falls back to the unauthenticated endpoint when the token provider throws
    /// `KeychainServiceError.osStatusError(errSecItemNotFound)`, covering the race condition where
    /// the user logs out between the `isAuthenticated` check and the actual token lookup.
    func test_getConfig_keychainItemNotFound_fallsBackToUnauthenticated() async throws {
        let account = Account.fixture()
        stateService.activeAccount = account
        stateService.isAuthenticated[account.profile.userId] = true
        client.result = .httpSuccess(testData: .validServerConfig)
        accountTokenProvider.getTokenThrowableError = KeychainServiceError.osStatusError(errSecItemNotFound)

        _ = try await subject.getConfig()

        let request = try XCTUnwrap(client.requests.last)
        XCTAssertEqual(request.url.absoluteString, "https://example.com/api/config")
        XCTAssertNil(request.headers["Authorization"])
    }

    /// `getConfig()` falls back to the unauthenticated endpoint when the token provider throws
    /// `KeychainServiceError.keyNotFound`, covering the race condition where the user logs out
    /// between the `isAuthenticated` check and the actual token lookup.
    func test_getConfig_keychainKeyNotFound_fallsBackToUnauthenticated() async throws {
        let account = Account.fixture()
        stateService.activeAccount = account
        stateService.isAuthenticated[account.profile.userId] = true
        client.result = .httpSuccess(testData: .validServerConfig)
        accountTokenProvider.getTokenThrowableError = KeychainServiceError.keyNotFound(
            MockKeychainItem(unformattedKey: "accessToken"),
        )

        _ = try await subject.getConfig()

        let request = try XCTUnwrap(client.requests.last)
        XCTAssertEqual(request.url.absoluteString, "https://example.com/api/config")
        XCTAssertNil(request.headers["Authorization"])
    }

    /// `getConfig()` propagates errors from the token provider that are not keychain item-not-found
    /// errors, ensuring unrelated failures are not accidentally swallowed.
    func test_getConfig_nonKeychainError_propagates() async throws {
        let account = Account.fixture()
        stateService.activeAccount = account
        stateService.isAuthenticated[account.profile.userId] = true
        accountTokenProvider.getTokenThrowableError = KeychainServiceError.accessControlFailed(nil)

        await assertAsyncThrows(error: KeychainServiceError.accessControlFailed(nil)) {
            _ = try await subject.getConfig()
        }
    }
}
