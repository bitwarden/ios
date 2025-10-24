import Foundation

// MARK: - SharedKeychainItem

/// Enumeration of support Keychain Items that can be placed in the `SharedKeychainRepository`
///
public enum SharedKeychainItem: Equatable, Hashable, Sendable {
    /// The keychain item for the authenticator encryption key.
    case authenticatorKey

    /// A date at which a BWPM account automatically logs out.
    case accountAutoLogout(userId: String)

    /// The storage key for this keychain item.
    ///
    public var unformattedKey: String {
        switch self {
        case .authenticatorKey:
            "authenticatorKey"
        case let .accountAutoLogout(userId: userId):
            "accountAutoLogout_\(userId)"
        }
    }
}

/// A storage layer for managing keychain items that are shared between Password Manager
/// and Authenticator. In particular, it is able to construct the appropriate queries to
/// talk with a `SharedKeychainService`.
///
public protocol SharedKeychainStorage {
    /// Deletes the value in the keychain for the given item.
    ///
    /// - Parameters:
    ///   - value: The value (Data) to be stored into the keychain
    ///   - item: The item for which to store the value in the keychain.
    ///
    func deleteValue(for item: SharedKeychainItem) async throws

    /// Retrieve the value for the specific item from the Keychain Service.
    ///
    /// - Parameter item: the keychain item for which to retrieve a value.
    /// - Returns: The value (Data) stored in the keychain for the given item.
    ///
    func getValue<T: Codable>(for item: SharedKeychainItem) async throws -> T

    /// Store a given value into the keychain for the given item.
    ///
    /// - Parameters:
    ///   - value: The value (Data) to be stored into the keychain
    ///   - item: The item for which to store the value in the keychain.
    ///
    func setValue<T: Codable>(_ value: T, for item: SharedKeychainItem) async throws
}

public class DefaultSharedKeychainStorage: SharedKeychainStorage {
    // MARK: Properties

    /// The keychain service used by the repository
    ///
    private let keychainService: SharedKeychainService

    /// An identifier for the shared access group used by the application.
    ///
    /// Example: "group.com.8bit.bitwarden"
    ///
    private let sharedAppGroupIdentifier: String

    // MARK: Initialization

    /// Initialize a `DefaultSharedKeychainStorage`.
    ///
    /// - Parameters:
    ///   - keychainService: The keychain service used by the repository
    ///   - sharedAppGroupIdentifier: An identifier for the shared access group used by the application.
    public init(
        keychainService: SharedKeychainService,
        sharedAppGroupIdentifier: String,
    ) {
        self.keychainService = keychainService
        self.sharedAppGroupIdentifier = sharedAppGroupIdentifier
    }

    // MARK: Methods

    public func deleteValue(for item: SharedKeychainItem) async throws {
        try keychainService.delete(
            query: [
                kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
                kSecAttrAccessGroup: sharedAppGroupIdentifier,
                kSecAttrAccount: item.unformattedKey,
                kSecClass: kSecClassGenericPassword,
            ] as CFDictionary,
        )
    }

    public func getValue<T: Codable>(for item: SharedKeychainItem) async throws -> T {
        let foundItem = try keychainService.search(
            query: [
                kSecMatchLimit: kSecMatchLimitOne,
                kSecReturnData: true,
                kSecReturnAttributes: true,
                kSecAttrAccessGroup: sharedAppGroupIdentifier,
                kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
                kSecAttrAccount: item.unformattedKey,
                kSecClass: kSecClassGenericPassword,
            ] as CFDictionary,
        )

        guard let resultDictionary = foundItem as? [String: Any],
              let data = resultDictionary[kSecValueData as String] as? Data else {
            throw SharedKeychainServiceError.keyNotFound(item)
        }

        let object = try JSONDecoder.defaultDecoder.decode(T.self, from: data)
        return object
    }

    public func setValue<T: Codable>(_ value: T, for item: SharedKeychainItem) async throws {
        let valueData = try JSONEncoder.defaultEncoder.encode(value)
        let query = [
            kSecValueData: valueData,
            kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
            kSecAttrAccessGroup: sharedAppGroupIdentifier,
            kSecAttrAccount: item.unformattedKey,
            kSecClass: kSecClassGenericPassword,
        ] as CFDictionary

        try? keychainService.delete(query: query)

        try keychainService.add(
            attributes: query,
        )
    }
}
