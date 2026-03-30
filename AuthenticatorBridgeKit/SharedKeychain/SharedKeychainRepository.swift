import BitwardenKit
import Foundation

// MARK: - SharedKeychainItem

/// Enumeration of support Keychain Items that can be placed in the `SharedKeychainRepository`
///
public enum SharedKeychainItem: Equatable, KeychainItem {
    /// A date at which a BWPM account automatically logs out.
    case accountAutoLogout(userId: String)

    /// The keychain item for the authenticator encryption key.
    case authenticatorKey

    public var accessControlFlags: SecAccessControlCreateFlags? { nil }

    public var protection: CFTypeRef { kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly }

    /// The storage key for this keychain item.
    ///
    public var unformattedKey: String {
        switch self {
        case let .accountAutoLogout(userId: userId):
            "accountAutoLogout_\(userId)"
        case .authenticatorKey:
            "authenticatorKey"
        }
    }
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
    /// The keychain service facade used by the repository.
    let keychainServiceFacade: KeychainServiceFacade

    /// Initialize a `DefaultSharedKeychainRepository`.
    ///
    /// - Parameters:
    ///   - keychainServiceFacade: The keychain service facade used by the repository
    public init(keychainServiceFacade: KeychainServiceFacade) {
        self.keychainServiceFacade = keychainServiceFacade
    }

    public func deleteAuthenticatorKey() async throws {
        try await keychainServiceFacade.deleteValue(for: SharedKeychainItem.authenticatorKey)
    }

    /// Gets the authenticator key.
    ///
    /// - Returns: Data representing the authenticator key.
    ///
    public func getAuthenticatorKey() async throws -> Data {
        try await keychainServiceFacade.getValue(for: SharedKeychainItem.authenticatorKey)
    }

    /// Stores the access token for a user in the keychain.
    ///
    /// - Parameter value: The authenticator key to store.
    ///
    public func setAuthenticatorKey(_ value: Data) async throws {
        try await keychainServiceFacade.setValue(value, for: SharedKeychainItem.authenticatorKey)
    }

    /// Gets when a user account should automatically log out.
    ///
    /// - Parameters:
    ///   - userId: The user ID of the account
    /// - Returns: The time the user should be automatically logged out. If `nil`, then the user should not be.
    ///
    public func getAccountAutoLogoutTime(userId: String) async throws -> Date? {
        try await keychainServiceFacade.getValue(for: SharedKeychainItem.accountAutoLogout(userId: userId))
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
        try await keychainServiceFacade.setValue(value, for: SharedKeychainItem.accountAutoLogout(userId: userId))
    }
}
