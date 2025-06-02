import Foundation

// MARK: - SharedKeychainRepository

public protocol SharedKeychainRepository {
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

    func getLastActiveTime(application: SharedTimeoutApplication, userId: String) async throws -> Date?

    func setLastActiveTime(_ value: Date?, application: SharedTimeoutApplication, userId: String) async throws

    func getVaultTimeout(application: SharedTimeoutApplication, userId: String) async throws -> SessionTimeoutValue?

    func setVaultTimeout(_ value: SessionTimeoutValue?, application: SharedTimeoutApplication, userId: String) async throws
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

    public func getLastActiveTime(application: SharedTimeoutApplication, userId: String) async throws -> Date? {
        nil
//        try await storage.getValue(for: .lastActiveTime(application: application, userId: userId))
    }

    public func setLastActiveTime(_ value: Date?, application: SharedTimeoutApplication, userId: String) async throws {
//        try await storage.setValue(value, for: .lastActiveTime(application: application, userId: userId))
    }

    public func getVaultTimeout(application: SharedTimeoutApplication, userId: String) async throws -> SessionTimeoutValue? {
        .never
//        try await storage.getValue(for: .vaultTimeout(application: application, userId: userId))
    }

    public func setVaultTimeout(_ value: SessionTimeoutValue?, application: SharedTimeoutApplication, userId: String) async throws {
//        try await storage.setValue(value, for: .vaultTimeout(application: application, userId: userId))
    }
}

/// A repository for managing keychain items to be shared between the main Bitwarden app and the Authenticator app.
///
//public protocol SharedKeychainRepository: AnyObject {
//    func getSharedValue(for item: SharedKeychainItem) async throws -> Data
//    func setSharedValue(_ value: Data, for item: SharedKeychainItem) async throws
//    func deleteSharedValue(for item: SharedKeychainItem) async throws
//}

//extension SharedKeychainRepository {
//    /// Attempts to delete the authenticator key from the keychain.
//    ///
//    func deleteAuthenticatorKey() async throws {
//        try await deleteSharedValue(for: .authenticatorKey)
//    }
//
//    /// Gets the authenticator key.
//    ///
//    /// - Returns: Data representing the authenticator key.
//    ///
//    func getAuthenticatorKey() async throws -> Data {
//        try await getSharedValue(for: .authenticatorKey)
//    }
//
//    /// Stores the access token for a user in the keychain.
//    ///
//    /// - Parameter value: The authenticator key to store.
//    ///
//    func setAuthenticatorKey(_ value: Data) async throws {
//        try await setSharedValue(value, for: .authenticatorKey)
//    }
//
//    func getLastActiveTime(application: SharedTimeoutApplication, userId: String) async throws -> Data {
//        try await getSharedValue(for: .lastActiveTime(application: application, userId: userId))
//    }
//
//    func setLastActiveTime(_ value: Data, application: SharedTimeoutApplication, userId: String) async throws {
//        try await setSharedValue(value, for: .lastActiveTime(application: application, userId: userId))
//    }
//
//    func getVaultTimeout(application: SharedTimeoutApplication, userId: String) async throws -> Data {
//        try await getSharedValue(for: .vaultTimeout(application: application, userId: userId))
//    }
//
//    func setVaultTimeout(_ value: Data, application: SharedTimeoutApplication, userId: String) async throws {
//        try await setSharedValue(value, for: .vaultTimeout(application: application, userId: userId))
//    }
//}
//
//// MARK: - DefaultKeychainRepository
//
///// A concrete implementation of the `SharedKeychainRepository` protocol.
/////
//public class DefaultSharedKeychainRepository: SharedKeychainRepository {
//    // MARK: Properties
//
//    /// An identifier for the shared access group used by the application.
//    ///
//    /// Example: "group.com.8bit.bitwarden"
//    ///
//    private let sharedAppGroupIdentifier: String
//
//    /// The keychain service used by the repository
//    ///
//    private let keychainService: AuthenticatorKeychainService
//
//    // MARK: Initialization
//
//    /// Initialize a `DefaultSharedKeychainRepository`.
//    ///
//    /// - Parameters:
//    ///   - sharedAppGroupIdentifier: An identifier for the shared access group used by the application.
//    ///   - keychainService: The keychain service used by the repository
//    public init(
//        sharedAppGroupIdentifier: String,
//        keychainService: AuthenticatorKeychainService
//    ) {
//        self.sharedAppGroupIdentifier = sharedAppGroupIdentifier
//        self.keychainService = keychainService
//    }
//
//    // MARK: Methods
//
//    /// Retrieve the value for the specific item from the Keychain Service.
//    ///
//    /// - Parameter item: the keychain item for which to retrieve a value.
//    /// - Returns: The value (Data) stored in the keychain for the given item.
//    ///
//    public func getSharedValue(for item: SharedKeychainItem) async throws -> Data {
//        let foundItem = try keychainService.search(
//            query: [
//                kSecMatchLimit: kSecMatchLimitOne,
//                kSecReturnData: true,
//                kSecReturnAttributes: true,
//                kSecAttrAccessGroup: sharedAppGroupIdentifier,
//                kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
//                kSecAttrAccount: item.unformattedKey,
//                kSecClass: kSecClassGenericPassword,
//            ] as CFDictionary
//        )
//
//        guard let resultDictionary = foundItem as? [String: Any],
//              let data = resultDictionary[kSecValueData as String] as? Data else {
//            throw AuthenticatorKeychainServiceError.keyNotFound(item)
//        }
//
//        return data
//    }
//
//    /// Store a given value into the keychain for the given item.
//    ///
//    /// - Parameters:
//    ///   - value: The value (Data) to be stored into the keychain
//    ///   - item: The item for which to store the value in the keychain.
//    ///
//    public func setSharedValue(_ value: Data, for item: SharedKeychainItem) async throws {
//        let query = [
//            kSecValueData: value,
//            kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
//            kSecAttrAccessGroup: sharedAppGroupIdentifier,
//            kSecAttrAccount: item.unformattedKey,
//            kSecClass: kSecClassGenericPassword,
//        ] as CFDictionary
//
//        try? keychainService.delete(query: query)
//
//        try keychainService.add(
//            attributes: query
//        )
//    }
//
//    public func deleteSharedValue(for item: SharedKeychainItem) async throws {
//        try keychainService.delete(
//            query: [
//                kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
//                kSecAttrAccessGroup: sharedAppGroupIdentifier,
//                kSecAttrAccount: item.unformattedKey,
//                kSecClass: kSecClassGenericPassword,
//            ] as CFDictionary
//        )
//
//    }
//}
