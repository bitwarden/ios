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

    /// The service that persists app settings.
    let appSettingsStore: AppSettingsStore

    // MARK: Initialization

    /// Initialize a `DefaultTokenService`.
    ///
    /// - Parameter appSettingsStore: The service that persists app settings.
    ///
    init(appSettingsStore: AppSettingsStore) {
        self.appSettingsStore = appSettingsStore
    }

    // MARK: Methods

    func getAccessToken() async throws -> String {
        guard let account = appSettingsStore.state?.activeAccount else {
            throw TokenServiceError.noActiveAccount
        }
        return account.tokens.accessToken
    }

    func getRefreshToken() async throws -> String {
        guard let account = appSettingsStore.state?.activeAccount else {
            throw TokenServiceError.noActiveAccount
        }
        return account.tokens.refreshToken
    }

    func setTokens(accessToken: String, refreshToken: String) async throws {
        guard var state = appSettingsStore.state,
              let activeUserId = state.activeUserId
        else {
            throw TokenServiceError.noActiveAccount
        }

        state.accounts[activeUserId]?.tokens = Account.AccountTokens(
            accessToken: accessToken,
            refreshToken: refreshToken
        )
        appSettingsStore.state = state
    }
}
