import BitwardenKit
import Foundation

// MARK: - SharedKeychainRepository

/// A repository for managing keychain items to be shared between Password Manager and Authenticator.
/// This should be the entry point in retrieving items from the shared keychain.
public protocol SharedKeychainRepository {
    /// Deletes the authenticator key.
    ///
    func deleteAuthenticatorKey() async throws

    /// Gets the authenticator key.
    ///
    /// - Returns: Data representing the authenticator key.
    ///
    func getAuthenticatorKey() async throws -> Data

    /// Stores the access token for a user in the keychain.
    ///
    /// - Parameter value: The authenticator key to store.
    ///
    func setAuthenticatorKey(_ value: Data) async throws

    /// Gets when a user account should automatically log out.
    ///
    /// - Parameters:
    ///   - userId: The user ID of the account
    /// - Returns: The time the user should be automatically logged out. If `nil`, then the user should not be.
    ///
    func getAccountAutoLogoutTime(
        userId: String,
    ) async throws -> Date?

    /// Sets when a user account should automatically log out.
    ///
    /// - Parameters:
    ///   - value: when the user should be automatically logged out
    ///   - userId: The user ID of the account
    ///
    func setAccountAutoLogoutTime(
        _ value: Date?,
        userId: String,
    ) async throws
}

public class DefaultSharedKeychainRepository: SharedKeychainRepository {
    /// The shared keychain storage used by the repository.
    let storage: SharedKeychainStorage

    /// Initialize a `DefaultSharedKeychainStorage`.
    ///
    /// - Parameters:
    ///   - storage: The shared keychain storage used by the repository
    public init(storage: SharedKeychainStorage) {
        self.storage = storage
    }

    public func deleteAuthenticatorKey() async throws {
        try await storage.deleteValue(for: .authenticatorKey)
    }

    /// Gets the authenticator key.
    ///
    /// - Returns: Data representing the authenticator key.
    ///
    public func getAuthenticatorKey() async throws -> Data {
        try await storage.getValue(for: .authenticatorKey)
    }

    /// Stores the access token for a user in the keychain.
    ///
    /// - Parameter value: The authenticator key to store.
    ///
    public func setAuthenticatorKey(_ value: Data) async throws {
        try await storage.setValue(value, for: .authenticatorKey)
    }

    /// Gets when a user account should automatically log out.
    ///
    /// - Parameters:
    ///   - userId: The user ID of the account
    /// - Returns: The time the user should be automatically logged out. If `nil`, then the user should not be.
    ///
    public func getAccountAutoLogoutTime(userId: String) async throws -> Date? {
        try await storage.getValue(for: .accountAutoLogout(userId: userId))
    }

    /// Sets when a user account should automatically log out.
    ///
    /// - Parameters:
    ///   - value: when the user should be automatically logged out
    ///   - userId: The user ID of the account
    ///
    public func setAccountAutoLogoutTime(
        _ value: Date?,
        userId: String,
    ) async throws {
        try await storage.setValue(value, for: .accountAutoLogout(userId: userId))
    }
}
