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

    /// The service that manages the account state.
    let stateService: StateService

    // MARK: Initialization

    /// Initialize a `DefaultTokenService`.
    ///
    /// - Parameter stateService: The service that manages the account state.
    ///
    init(stateService: StateService) {
        self.stateService = stateService
    }

    // MARK: Methods

    func getAccessToken() async throws -> String {
        try await stateService.getActiveAccount().tokens.accessToken
    }

    func getRefreshToken() async throws -> String {
        try await stateService.getActiveAccount().tokens.refreshToken
    }

    func setTokens(accessToken: String, refreshToken: String) async throws {
        try await stateService.setTokens(accessToken: accessToken, refreshToken: refreshToken)
    }
}
