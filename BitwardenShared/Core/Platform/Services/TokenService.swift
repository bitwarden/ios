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
    func setTokens(accessToken: String, refreshToken: String) async
}

// MARK: - TokenServiceError

/// The errors thrown from a `TokenService`.
///
enum TokenServiceError: Error {
    /// There isn't an active account to get tokens from.
    case noActiveAccount
}

// MARK: - DefaultTokenService

/// A default implementation of `TokenService`.
///
actor DefaultTokenService: TokenService {
    // MARK: Properties

    /// The account's access token.
    var accessToken: String?

    /// The account's refresh token.
    var refreshToken: String?

    // MARK: Methods

    func getAccessToken() async throws -> String {
        guard let accessToken else { throw TokenServiceError.noActiveAccount }
        return accessToken
    }

    func getRefreshToken() async throws -> String {
        guard let refreshToken else { throw TokenServiceError.noActiveAccount }
        return refreshToken
    }

    func setTokens(accessToken: String, refreshToken: String) async {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
    }
}
