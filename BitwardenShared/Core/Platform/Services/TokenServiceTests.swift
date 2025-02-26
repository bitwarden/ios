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

    /// `getIsExternal()` returns false if the user isn't an external user.
    func test_getIsExternal_false() async throws {
        // swiftlint:disable:next line_length
        let token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE2OTY5MDg4NzksInN1YiI6IjEzNTEyNDY3LTljZmUtNDNiMC05NjlmLTA3NTM0MDg0NzY0YiIsIm5hbWUiOiJCaXR3YXJkZW4gVXNlciIsImVtYWlsIjoidXNlckBiaXR3YXJkZW4uY29tIiwiZW1haWxfdmVyaWZpZWQiOnRydWUsImlhdCI6MTUxNjIzOTAyMiwicHJlbWl1bSI6ZmFsc2UsImFtciI6WyJBcHBsaWNhdGlvbiJdfQ.KDqC8kUaOAgBiUY8eeLa0a4xYWN8GmheXTFXmataFwM"
        keychainRepository.getAccessTokenResult = .success(token)
        stateService.activeAccount = .fixture()

        let isExternal = try await subject.getIsExternal()
        XCTAssertFalse(isExternal)
    }

    /// `getIsExternal()` returns true if the user is an external user.
    func test_getIsExternal_true() async throws {
        // swiftlint:disable:next line_length
        let token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE2OTY5MDg4NzksInN1YiI6IjEzNTEyNDY3LTljZmUtNDNiMC05NjlmLTA3NTM0MDg0NzY0YiIsIm5hbWUiOiJCaXR3YXJkZW4gVXNlciIsImVtYWlsIjoidXNlckBiaXR3YXJkZW4uY29tIiwiZW1haWxfdmVyaWZpZWQiOnRydWUsImlhdCI6MTUxNjIzOTAyMiwicHJlbWl1bSI6ZmFsc2UsImFtciI6WyJleHRlcm5hbCJdfQ.POnwEWm09reMUfiHKZP-PIW_fvIl-ZzXs9pLZJVYf9A"
        keychainRepository.getAccessTokenResult = .success(token)
        stateService.activeAccount = .fixture()

        let isExternal = try await subject.getIsExternal()
        XCTAssertTrue(isExternal)
    }

    /// `getIsExternal()` throws an error if there's no active account.
    func test_getIsExternal_noAccount() async throws {
        await assertAsyncThrows(error: StateServiceError.noActiveAccount) {
            _ = try await subject.getIsExternal()
        }
    }

    /// `getIsExternal()` throws an error if fetching the user's access token fails.
    func test_getIsExternal_tokenError() async throws {
        keychainRepository.getAccessTokenResult = .failure(BitwardenTestError.example)
        stateService.activeAccount = .fixture()

        await assertAsyncThrows(error: BitwardenTestError.example) {
            _ = try await subject.getIsExternal()
        }
    }

    /// `getIsExternal()` throws an error if fetching the user's access token fails.
    func test_getIsExternal_tokenParsingError() async throws {
        keychainRepository.getAccessTokenResult = .success("token")
        stateService.activeAccount = .fixture()

        await assertAsyncThrows(error: TokenParserError.invalidToken) {
            _ = try await subject.getIsExternal()
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
