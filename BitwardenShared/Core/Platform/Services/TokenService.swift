import BitwardenKit
import BitwardenSdk
import Foundation

/// A protocol for a `TokenService` which manages accessing and updating the active account's tokens.
///
protocol TokenService: AnyObject {
    /// Returns the access token for the current account.
    ///
    /// - Returns: The access token for the current account.
    ///
    func getAccessToken() async throws -> String

    /// Returns the access token for a specific user.
    ///
    /// - Parameter userId: The user ID to get the access token for.
    /// - Returns: The access token for the specified user.
    ///
    func getAccessToken(userId: String) async throws -> String

    /// Returns the access token's expiration date for the current account.
    ///
    /// - Returns: The access token's expiration date for the current account.
    ///
    func getAccessTokenExpirationDate() async throws -> Date?

    /// Returns the active account's user ID.
    ///
    /// - Returns: The active account's user ID.
    ///
    func getActiveAccountId() async throws -> String

    /// Returns whether the user is an external user.
    ///
    /// - Returns: Whether the user is an external user.
    ///
    func getIsExternal() async throws -> Bool

    /// Returns the refresh token for the current account.
    ///
    /// - Returns: The refresh token for the current account.
    ///
    func getRefreshToken() async throws -> String

    /// Returns the refresh token for a specific user.
    ///
    /// - Parameter userId: The user ID to get the refresh token for.
    /// - Returns: The refresh token for the specified user.
    ///
    func getRefreshToken(userId: String) async throws -> String

    /// Sets a new access and refresh token for the current account.
    ///
    /// - Parameters:
    ///   - accessToken: The account's updated access token.
    ///   - refreshToken: The account's updated refresh token.
    ///   - expirationDate: The access token's expiration date.
    ///
    func setTokens(accessToken: String, refreshToken: String, expirationDate: Date) async throws

    /// Sets a new access and refresh token for a specific user.
    ///
    /// - Parameters:
    ///   - accessToken: The account's updated access token.
    ///   - refreshToken: The account's updated refresh token.
    ///   - expirationDate: The access token's expiration date.
    ///   - userId: The user ID to set the tokens for.
    ///
    func setTokens(accessToken: String, refreshToken: String, expirationDate: Date, userId: String) async throws
}

// MARK: - DefaultTokenService

/// A default implementation of `TokenService`.
///
actor DefaultTokenService: TokenService {
    // MARK: Properties

    /// The service used by the application to report non-fatal errors.
    let errorReporter: ErrorReporter

    /// The repository used to manages keychain items.
    let keychainRepository: KeychainRepository

    /// The service that manages the account state.
    let stateService: StateService

    // MARK: Initialization

    /// Initialize a `DefaultTokenService`.
    ///
    /// - Parameters
    ///   - errorReporter: The service used by the application to report non-fatal errors.
    ///   - keychainRepository: The repository used to manages keychain items.
    ///   - stateService: The service that manages the account state.
    ///
    init(
        errorReporter: ErrorReporter,
        keychainRepository: KeychainRepository,
        stateService: StateService,
    ) {
        self.errorReporter = errorReporter
        self.keychainRepository = keychainRepository
        self.stateService = stateService
    }

    // MARK: Methods

    func getAccessToken() async throws -> String {
        let userId = try await stateService.getActiveAccountId()
        return try await keychainRepository.getAccessToken(userId: userId)
    }

    func getAccessTokenExpirationDate() async throws -> Date? {
        try await stateService.getAccessTokenExpirationDate()
    }

    func getIsExternal() async throws -> Bool {
        let accessToken: String = try await getAccessToken()
        let tokenPayload = try TokenParser.parseToken(accessToken)
        return tokenPayload.isExternal
    }

    func getRefreshToken() async throws -> String {
        let userId = try await stateService.getActiveAccountId()
        return try await keychainRepository.getRefreshToken(userId: userId)
    }

    func setTokens(accessToken: String, refreshToken: String, expirationDate: Date) async throws {
        let userId = try await stateService.getActiveAccountId()
        try await keychainRepository.setAccessToken(accessToken, userId: userId)
        try await keychainRepository.setRefreshToken(refreshToken, userId: userId)
        await stateService.setAccessTokenExpirationDate(expirationDate, userId: userId)
    }

    func getAccessToken(userId: String) async throws -> String {
        try await keychainRepository.getAccessToken(userId: userId)
    }

    func getActiveAccountId() async throws -> String {
        try await stateService.getActiveAccountId()
    }

    func getRefreshToken(userId: String) async throws -> String {
        try await keychainRepository.getRefreshToken(userId: userId)
    }

    func setTokens(accessToken: String, refreshToken: String, expirationDate: Date, userId: String) async throws {
        try await keychainRepository.setAccessToken(accessToken, userId: userId)
        try await keychainRepository.setRefreshToken(refreshToken, userId: userId)
        await stateService.setAccessTokenExpirationDate(expirationDate, userId: userId)
    }
}

// MARK: ClientManagedTokens (SDK)

extension DefaultTokenService: ClientManagedTokens {
    /// Gets the access token for the SDK, nil if any errors are thrown.
    func getAccessToken() async -> String? {
        // TODO: PM-21846 Returning `nil` temporarily until we add validation
        // given that the SDK expects non-expired token.
        nil
    }
}
