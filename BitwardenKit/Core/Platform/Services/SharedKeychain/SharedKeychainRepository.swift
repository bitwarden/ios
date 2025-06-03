import Foundation

public enum SharedTimeoutApplication: String {
    case authenticator = "bwa"
    case passwordManager = "pm"
}

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

    /// Gets the last active time the user used the specified application.
    ///
    /// - Parameters:
    ///   - application: The application to get the value for
    /// - Returns: The user's last active time in a specified application, if known
    ///
    func getLastActiveTime(
        application: SharedTimeoutApplication,
        userId: String
    ) async throws -> Date?

    /// Sets the last active time for a user using the specified application.
    ///
    /// - Parameters:
    ///   - value: the date to save for a user's last active time for an application
    ///   - application: The application to set the value for
    ///
    func setLastActiveTime(
        _ value: Date?,
        application: SharedTimeoutApplication,
        userId: String
    ) async throws

    /// Gets the vault timeout value for a user using the specified application.
    /// - Parameters:
    ///   - application: The application to get the value for
    /// - Returns: The user's vault timeout value in a specified application, if known
    ///
    func getVaultTimeout(
        application: SharedTimeoutApplication,
        userId: String
    ) async throws -> SessionTimeoutValue?

    /// Sets the vault timeout for a user using the specified application.
    ///
    /// - Parameters:
    ///   - value: the date to save for a user's last active time for an application
    ///   - application: The application to set the value for
    ///
    func setVaultTimeout(
        _ value: SessionTimeoutValue?,
        application: SharedTimeoutApplication,
        userId: String
    ) async throws
}

public class DefaultSharedKeychainRepository: SharedKeychainRepository {
    let storage: SharedKeychainStorage

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

    public func getLastActiveTime(
        application: SharedTimeoutApplication,
        userId: String
    ) async throws -> Date? {
        try await storage.getValue(for: .lastActiveTime(application: application, userId: userId))
    }

    public func setLastActiveTime(
        _ value: Date?,
        application: SharedTimeoutApplication,
        userId: String
    ) async throws {
        try await storage.setValue(value, for: .lastActiveTime(application: application, userId: userId))
    }

    public func getVaultTimeout(
        application: SharedTimeoutApplication,
        userId: String
    ) async throws -> SessionTimeoutValue? {
        try await storage.getValue(for: .vaultTimeout(application: application, userId: userId))
    }

    public func setVaultTimeout(
        _ value: SessionTimeoutValue?,
        application: SharedTimeoutApplication,
        userId: String
    ) async throws {
        try await storage.setValue(value, for: .vaultTimeout(application: application, userId: userId))
    }
}
