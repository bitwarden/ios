import BitwardenKit
import BitwardenKitMocks
import Security
import Testing
import TestHelpers

@testable import BitwardenShared
@testable import BitwardenSharedMocks

@MainActor
struct ConfigAPIServiceTests {
    // MARK: Properties

    let accountTokenProvider: MockAccountTokenProvider
    let activeAccountStateProvider: MockActiveAccountStateProvider
    let client: MockHTTPClient
    let stateService: MockStateService
    let subject: ConfigAPIService

    // MARK: Initialization

    init() {
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

    // MARK: Tests

    /// `getConfig()` performs the config request authenticated.
    @Test
    func getConfig() async throws {
        let account = Account.fixture()
        stateService.activeAccount = account
        stateService.isAuthenticated[account.profile.userId] = true
        client.result = .httpSuccess(testData: .validServerConfig)

        _ = try await subject.getConfig()

        let request = try #require(client.requests.last)
        #expect(request.method == .get)
        #expect(request.url.absoluteString == "https://example.com/api/config")
        #expect(request.body == nil)
        #expect(request.headers["Authorization"] != nil)
    }

    /// `getConfig()` performs the config request unauthenticated.
    @Test
    func getConfig_unauthenticated() async throws {
        let account = Account.fixture()
        stateService.activeAccount = account
        stateService.isAuthenticated[account.profile.userId] = false
        client.result = .httpSuccess(testData: .validServerConfig)

        _ = try await subject.getConfig()

        let request = try #require(client.requests.last)
        #expect(request.method == .get)
        #expect(request.url.absoluteString == "https://example.com/api/config")
        #expect(request.body == nil)
        #expect(request.headers["Authorization"] == nil)
    }

    /// `getConfig()` performs the config request unauthenticated because there is no active account.
    @Test
    func getConfig_unauthenticatedNoAccount() async throws {
        client.result = .httpSuccess(testData: .validServerConfig)

        _ = try await subject.getConfig()

        let request = try #require(client.requests.last)
        #expect(request.method == .get)
        #expect(request.url.absoluteString == "https://example.com/api/config")
        #expect(request.body == nil)
        #expect(request.headers["Authorization"] == nil)
    }

    /// `getConfig()` falls back to the unauthenticated endpoint when the token provider throws
    /// `KeychainServiceError.osStatusError(errSecItemNotFound)`, covering the race condition where
    /// the user logs out between the `isAuthenticated` check and the actual token lookup.
    @Test
    func getConfig_keychainItemNotFound_fallsBackToUnauthenticated() async throws {
        let account = Account.fixture()
        stateService.activeAccount = account
        stateService.isAuthenticated[account.profile.userId] = true
        client.result = .httpSuccess(testData: .validServerConfig)
        accountTokenProvider.getTokenThrowableError = KeychainServiceError.osStatusError(errSecItemNotFound)

        _ = try await subject.getConfig()

        let request = try #require(client.requests.last)
        #expect(request.url.absoluteString == "https://example.com/api/config")
        #expect(request.headers["Authorization"] == nil)
    }

    /// `getConfig()` falls back to the unauthenticated endpoint when the token provider throws
    /// `KeychainServiceError.keyNotFound`, covering the race condition where the user logs out
    /// between the `isAuthenticated` check and the actual token lookup.
    @Test
    func getConfig_keychainKeyNotFound_fallsBackToUnauthenticated() async throws {
        let account = Account.fixture()
        stateService.activeAccount = account
        stateService.isAuthenticated[account.profile.userId] = true
        client.result = .httpSuccess(testData: .validServerConfig)
        accountTokenProvider.getTokenThrowableError = KeychainServiceError.keyNotFound(
            MockKeychainItem(unformattedKey: "accessToken"),
        )

        _ = try await subject.getConfig()

        let request = try #require(client.requests.last)
        #expect(request.url.absoluteString == "https://example.com/api/config")
        #expect(request.headers["Authorization"] == nil)
    }

    /// `getConfig()` propagates errors from the token provider that are not keychain item-not-found
    /// errors, ensuring unrelated failures are not accidentally swallowed.
    @Test
    func getConfig_nonKeychainError_propagates() async throws {
        let account = Account.fixture()
        stateService.activeAccount = account
        stateService.isAuthenticated[account.profile.userId] = true
        accountTokenProvider.getTokenThrowableError = KeychainServiceError.accessControlFailed(nil)

        await #expect(throws: KeychainServiceError.accessControlFailed(nil)) {
            _ = try await subject.getConfig()
        }
    }
}
