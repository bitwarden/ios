import XCTest

@testable import BitwardenShared

class TokenServiceTests: BitwardenTestCase {
    // MARK: Properties

    var appSettingsStore: MockAppSettingsStore!
    var subject: DefaultTokenService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        appSettingsStore = MockAppSettingsStore()

        subject = DefaultTokenService(appSettingsStore: appSettingsStore)
    }

    override func tearDown() {
        super.tearDown()

        appSettingsStore = nil
        subject = nil
    }

    // MARK: Tests

    /// `getAccessToken()` returns the access token stored in the store for the active account.
    func test_getAccessToken() async throws {
        appSettingsStore.state = .fixture()

        let accessToken = try await subject.getAccessToken()
        XCTAssertEqual(accessToken, "ACCESS_TOKEN")

        appSettingsStore.state = State.fixture(
            accounts: [
                "1": .fixture(tokens: Account.AccountTokens(accessToken: "🔑", refreshToken: "🔒")),
            ]
        )

        let updatedAccessToken = try await subject.getAccessToken()
        XCTAssertEqual(updatedAccessToken, "🔑")
    }

    /// `getAccessToken()` returns the access token stored in the store for the active account.
    func test_getAccessToken_multipleAccounts() async throws {
        appSettingsStore.state = .fixture(
            accounts: [
                "1": .fixture(tokens: Account.AccountTokens(accessToken: "🔑", refreshToken: "🔒")),
                "2": .fixture(tokens: Account.AccountTokens(accessToken: "🧑‍💻", refreshToken: "📱")),
            ],
            activeUserId: "2"
        )

        let accessToken = try await subject.getAccessToken()
        XCTAssertEqual(accessToken, "🧑‍💻")
    }

    /// `getAccessToken()` throws an error if there isn't an active account.
    func test_getAccessToken_noAccount() async {
        appSettingsStore.state = nil

        await assertAsyncThrows(error: TokenServiceError.noActiveAccount) {
            _ = try await subject.getAccessToken()
        }
    }

    /// `getRefreshToken()` returns the refresh token stored in the store for the active account.
    func test_getRefreshToken() async throws {
        appSettingsStore.state = .fixture()

        let refreshToken = try await subject.getRefreshToken()
        XCTAssertEqual(refreshToken, "REFRESH_TOKEN")

        appSettingsStore.state = State.fixture(
            accounts: [
                "1": .fixture(tokens: Account.AccountTokens(accessToken: "🔑", refreshToken: "🔒")),
            ]
        )

        let updatedRefreshToken = try await subject.getRefreshToken()
        XCTAssertEqual(updatedRefreshToken, "🔒")
    }

    /// `getRefreshToken()` returns the refresh token stored in the store for the active account.
    func test_getRefreshToken_multipleAccounts() async throws {
        appSettingsStore.state = .fixture(
            accounts: [
                "1": .fixture(tokens: Account.AccountTokens(accessToken: "🔑", refreshToken: "🔒")),
                "2": .fixture(tokens: Account.AccountTokens(accessToken: "🧑‍💻", refreshToken: "📱")),
            ],
            activeUserId: "2"
        )

        let refreshToken = try await subject.getRefreshToken()
        XCTAssertEqual(refreshToken, "📱")
    }

    /// `getRefreshToken()` throws an error if there isn't an active account.
    func test_getRefreshToken_noAccount() async {
        appSettingsStore.state = nil

        await assertAsyncThrows(error: TokenServiceError.noActiveAccount) {
            _ = try await subject.getRefreshToken()
        }
    }

    /// `setTokens()` sets the tokens in the store for the active account.
    func test_setTokens() async throws {
        appSettingsStore.state = .fixture()

        try await subject.setTokens(accessToken: "🔑", refreshToken: "🔒")

        let tokens = try XCTUnwrap(appSettingsStore.state?.activeAccount?.tokens)
        XCTAssertEqual(tokens.accessToken, "🔑")
        XCTAssertEqual(tokens.refreshToken, "🔒")
    }

    /// `setTokens()` sets the tokens in the store for the active account.
    func test_setTokens_multipleAccounts() async throws {
        appSettingsStore.state = .fixture(
            accounts: [
                "1": .fixture(tokens: Account.AccountTokens(accessToken: "🔑", refreshToken: "🔒")),
                "2": .fixture(tokens: Account.AccountTokens(accessToken: "🧑‍💻", refreshToken: "📱")),
            ],
            activeUserId: "2"
        )

        try await subject.setTokens(accessToken: "👻", refreshToken: "🎃")

        let state = appSettingsStore.state
        XCTAssertEqual(state?.accounts["1"]?.tokens, .init(accessToken: "🔑", refreshToken: "🔒"))
        XCTAssertEqual(state?.accounts["2"]?.tokens, .init(accessToken: "👻", refreshToken: "🎃"))
    }

    /// `setTokens()` throws an error if there isn't an active account.
    func test_setTokens_noAccount() async throws {
        appSettingsStore.state = nil

        await assertAsyncThrows(error: TokenServiceError.noActiveAccount) {
            try await subject.setTokens(accessToken: "🔑", refreshToken: "🔒")
        }
    }
}
