import XCTest

@testable import BitwardenShared

class TokenServiceTests: BitwardenTestCase {
    // MARK: Properties

    var keychainRepository: MockKeychainRepository!
    var stateService: MockStateService!
    var subject: DefaultTokenService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        keychainRepository = MockKeychainRepository()
        stateService = MockStateService()

        subject = DefaultTokenService(keychainRepository: keychainRepository, stateService: stateService)
    }

    override func tearDown() {
        super.tearDown()

        keychainRepository = nil
        stateService = nil
        subject = nil
    }

    // MARK: Tests

    /// `getAccessToken()` returns the access token stored in the state service for the active account.
    func test_getAccessToken() async throws {
        stateService.activeAccount = .fixture()

        let accessToken = try await subject.getAccessToken()
        XCTAssertEqual(accessToken, "ACCESS_TOKEN")

        keychainRepository.getAccessTokenResult = .success("🔑")

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

        keychainRepository.getRefreshTokenResult = .success("🔒")

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
            keychainRepository.mockStorage[keychainRepository.formattedKey(for: .accessToken(userId: "1"))],
            "🔑"
        )
        XCTAssertEqual(
            keychainRepository.mockStorage[keychainRepository.formattedKey(for: .refreshToken(userId: "1"))],
            "🔒"
        )
    }
}
