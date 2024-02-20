/// A protocol for a `TokenService` which manages accessing and updating the active account's tokens.
///
protocol TokenService: AnyObject {
    /// Returns the access token for the current account.
    ///
    /// - Returns: The access token for the current account.
    ///
    func getAccessToken() async throws -> String

    /// Returns the refresh token for the current account.
    ///
    /// - Returns: The refresh token for the current account.
    ///
    func getRefreshToken() async throws -> String

    /// Sets a new access and refresh token for the current account.
    ///
    /// - Parameters:
    ///   - accessToken: The account's updated access token.
    ///   - refreshToken: The account's updated refresh token.
    ///
    func setTokens(accessToken: String, refreshToken: String) async throws
}

// MARK: - DefaultTokenService

/// A default implementation of `TokenService`.
///
actor DefaultTokenService: TokenService {
    // MARK: Properties

    /// The repository used to manages keychain items.
    let keychainRepository: KeychainRepository

    /// The service that manages the account state.
    let stateService: StateService

    // MARK: Initialization

    /// Initialize a `DefaultTokenService`.
    ///
    /// - Parameters
    ///   - keychainRepository: The repository used to manages keychain items.
    ///   - stateService: The service that manages the account state.
    ///
    init(
        keychainRepository: KeychainRepository,
        stateService: StateService
    ) {
        self.keychainRepository = keychainRepository
        self.stateService = stateService
    }

    // MARK: Methods

    func getAccessToken() async throws -> String {
        let userId = try await stateService.getActiveAccountId()
        return try await keychainRepository.getAccessToken(userId: userId)
    }

    func getRefreshToken() async throws -> String {
        let userId = try await stateService.getActiveAccountId()
        return try await keychainRepository.getRefreshToken(userId: userId)
    }

    func setTokens(accessToken: String, refreshToken: String) async throws {
        let userId = try await stateService.getActiveAccountId()
        try await keychainRepository.setAccessToken(accessToken, userId: userId)
        try await keychainRepository.setRefreshToken(refreshToken, userId: userId)
    }
}
