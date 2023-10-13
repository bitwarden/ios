import XCTest

@testable import BitwardenShared

class TokenServiceTests: BitwardenTestCase {
    // MARK: Properties

    var stateService: MockStateService!
    var subject: DefaultTokenService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        stateService = MockStateService()

        subject = DefaultTokenService(stateService: stateService)
    }

    override func tearDown() {
        super.tearDown()

        stateService = nil
        subject = nil
    }

    // MARK: Tests

    /// `getAccessToken()` returns the access token stored in the state service for the active account.
    func test_getAccessToken() async throws {
        stateService.activeAccount = .fixture()

        let accessToken = try await subject.getAccessToken()
        XCTAssertEqual(accessToken, "ACCESS_TOKEN")

        stateService.activeAccount = .fixture(tokens: Account.AccountTokens(accessToken: "🔑", refreshToken: "🔒"))

        let updatedAccessToken = try await subject.getAccessToken()
        XCTAssertEqual(updatedAccessToken, "🔑")
    }

    /// `getAccessToken()` throws an error if there isn't an active account.
    func test_getAccessToken_noAccount() async {
        stateService.activeAccount = nil

        await assertAsyncThrows(error: StateServiceError.noActiveAccount) {
            _ = try await subject.getAccessToken()
        }
    }

    /// `getRefreshToken()` returns the refresh token stored in the state service for the active account.
    func test_getRefreshToken() async throws {
        stateService.activeAccount = .fixture()

        let refreshToken = try await subject.getRefreshToken()
        XCTAssertEqual(refreshToken, "REFRESH_TOKEN")

        stateService.activeAccount = .fixture(tokens: Account.AccountTokens(accessToken: "🔑", refreshToken: "🔒"))

        let updatedRefreshToken = try await subject.getRefreshToken()
        XCTAssertEqual(updatedRefreshToken, "🔒")
    }

    /// `getRefreshToken()` throws an error if there isn't an active account.
    func test_getRefreshToken_noAccount() async {
        stateService.activeAccount = nil

        await assertAsyncThrows(error: StateServiceError.noActiveAccount) {
            _ = try await subject.getRefreshToken()
        }
    }

    /// `setTokens()` sets the tokens in the state service for the active account.
    func test_setTokens() async throws {
        stateService.activeAccount = .fixture()

        try await subject.setTokens(accessToken: "🔑", refreshToken: "🔒")

        XCTAssertEqual(
            stateService.accountTokens,
            Account.AccountTokens(accessToken: "🔑", refreshToken: "🔒")
        )
    }
}
