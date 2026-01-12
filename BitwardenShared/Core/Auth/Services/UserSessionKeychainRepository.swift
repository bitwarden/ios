import Foundation

// MARK: UserSessionKeychainRepository

/// A service that provides access to keychain values related to the user session.
///
protocol UserSessionKeychainRepository { // sourcery: AutoMockable
    // MARK: Last Active Time

    /// Attempts to delete the last active time from the keychain.
    ///
    /// - Parameter userId: The user ID associated with the last active time.
    ///
    func deleteLastActiveTime(userId: String) async throws

    /// Gets the stored last active time for a user from the keychain.
    ///
    /// - Parameter userId: The user ID associated with the stored last active time.
    /// - Returns: The last active time value.
    ///
    func getLastActiveTime(userId: String) async throws -> Date?

    /// Stores the last active time for a user in the keychain.
    ///
    /// - Parameters:
    ///   - date: The last active time to store.
    ///   - userId: The user's ID, used to get back the last active time later on.
    ///
    func setLastActiveTime(_ date: Date?, userId: String) async throws

    // MARK: Vault Timeout

    /// Attempts to delete the vault timeout from the keychain.
    ///
    /// - Parameter userId: The user ID associated with the vault timeout.
    ///
    func deleteVaultTimeout(userId: String) async throws

    /// Gets the stored vault timeout for a user from the keychain.
    ///
    /// - Parameter userId: The user ID associated with the stored vault timeout.
    /// - Returns: The vault timeout value.
    ///
    func getVaultTimeout(userId: String) async throws -> Int?

    /// Stores the vault timeout for a user in the keychain.
    ///
    /// - Parameters:
    ///   - minutes: The vault timeout to store, in minutes.
    ///   - userId: The user's ID, used to get back the vault timeout later on.
    ///
    func setVaultTimeout(minutes: Int, userId: String) async throws
}
