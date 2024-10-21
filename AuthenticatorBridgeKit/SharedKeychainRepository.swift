import Foundation

// MARK: - SharedKeychainItem

/// Enumeration of support Keychain Items that can be placed in the `SharedKeychainRepository`
///
public enum SharedKeychainItem: Equatable {
    /// The keychain item for the authenticator encryption key.
    case authenticatorKey

    /// The storage key for this keychain item.
    ///
    var unformattedKey: String {
        switch self {
        case .authenticatorKey:
            "authenticatorKey"
        }
    }
}

// MARK: - SharedKeychainRepository

/// A repository for managing keychain items to be shared between the main Bitwarden app and the Authenticator app.
///
public protocol SharedKeychainRepository: AnyObject {
    /// Attempts to delete the authenticator key from the keychain.
    ///
    func deleteAuthenticatorKey() throws

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
}

// MARK: - DefaultKeychainRepository

/// A concrete implementation of the `SharedKeychainRepository` protocol.
///
public class DefaultSharedKeychainRepository: SharedKeychainRepository {
    // MARK: Properties

    /// An identifier for the shared access group used by the application.
    ///
    /// Example: "group.com.8bit.bitwarden"
    ///
    private let sharedAppGroupIdentifier: String

    /// The keychain service used by the repository
    ///
    private let keychainService: AuthenticatorKeychainService

    // MARK: Initialization

    /// Initialize a `DefaultSharedKeychainRepository`.
    ///
    /// - Parameters:
    ///   - sharedAppGroupIdentifier: An identifier for the shared access group used by the application.
    ///   - keychainService: The keychain service used by the repository
    public init(
        sharedAppGroupIdentifier: String,
        keychainService: AuthenticatorKeychainService
    ) {
        self.sharedAppGroupIdentifier = sharedAppGroupIdentifier
        self.keychainService = keychainService
    }

    // MARK: Methods

    /// Retrieve the value for the specific item from the Keychain Service.
    ///
    /// - Parameter item: the keychain item for which to retrieve a value.
    /// - Returns: The value (Data) stored in the keychain for the given item.
    ///
    private func getSharedValue(for item: SharedKeychainItem) async throws -> Data {
        let foundItem = try keychainService.search(
            query: [
                kSecMatchLimit: kSecMatchLimitOne,
                kSecReturnData: true,
                kSecReturnAttributes: true,
                kSecAttrAccessGroup: sharedAppGroupIdentifier,
                kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
                kSecAttrAccount: item.unformattedKey,
                kSecClass: kSecClassGenericPassword,
            ] as CFDictionary
        )

        guard let resultDictionary = foundItem as? [String: Any],
              let data = resultDictionary[kSecValueData as String] as? Data else {
            throw AuthenticatorKeychainServiceError.keyNotFound(item)
        }

        return data
    }

    /// Store a given value into the keychain for the given item.
    ///
    /// - Parameters:
    ///   - value: The value (Data) to be stored into the keychain
    ///   - item: The item for which to store the value in the keychain.
    ///
    private func setSharedValue(_ value: Data, for item: SharedKeychainItem) async throws {
        let query = [
            kSecValueData: value,
            kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
            kSecAttrAccessGroup: sharedAppGroupIdentifier,
            kSecAttrAccount: item.unformattedKey,
            kSecClass: kSecClassGenericPassword,
        ] as CFDictionary

        try? keychainService.delete(query: query)

        try keychainService.add(
            attributes: query
        )
    }
}

public extension DefaultSharedKeychainRepository {
    /// Attempts to delete the authenticator key from the keychain.
    ///
    func deleteAuthenticatorKey() throws {
        try keychainService.delete(
            query: [
                kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
                kSecAttrAccessGroup: sharedAppGroupIdentifier,
                kSecAttrAccount: SharedKeychainItem.authenticatorKey.unformattedKey,
                kSecClass: kSecClassGenericPassword,
            ] as CFDictionary
        )
    }

    /// Gets the authenticator key.
    ///
    /// - Returns: Data representing the authenticator key.
    ///
    func getAuthenticatorKey() async throws -> Data {
        try await getSharedValue(for: .authenticatorKey)
    }

    /// Stores the access token for a user in the keychain.
    ///
    /// - Parameter value: The authenticator key to store.
    ///
    func setAuthenticatorKey(_ value: Data) async throws {
        try await setSharedValue(value, for: .authenticatorKey)
    }
}
