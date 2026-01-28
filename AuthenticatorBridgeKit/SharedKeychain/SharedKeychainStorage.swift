import BitwardenKit
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
            query: item.baseQuery(sharedAppGroupIdentifier: sharedAppGroupIdentifier),
        )
    }

    public func getValue<T: Codable>(for item: SharedKeychainItem) async throws -> T {
        var query = item.baseQueryAttributes(sharedAppGroupIdentifier: sharedAppGroupIdentifier)
        query[kSecMatchLimit] = kSecMatchLimitOne
        query[kSecReturnData] = true
        query[kSecReturnAttributes] = true

        let foundItem = try keychainService.search(query: query as CFDictionary)

        guard let resultDictionary = foundItem as? [String: Any],
              let data = resultDictionary[kSecValueData as String] as? Data else {
            throw SharedKeychainServiceError.keyNotFound(item)
        }

        let object = try JSONDecoder.defaultDecoder.decode(T.self, from: data)
        return object
    }

    public func setValue<T: Codable>(_ value: T, for item: SharedKeychainItem) async throws {
        let valueData = try JSONEncoder.defaultEncoder.encode(value)

        do {
            // Try to update first - if item exists, this avoids delete-then-add race condition
            try keychainService.update(
                query: item.baseQuery(sharedAppGroupIdentifier: sharedAppGroupIdentifier),
                attributes: [kSecValueData: valueData] as CFDictionary,
            )
        } catch KeychainServiceError.osStatusError(errSecItemNotFound) {
            // Item doesn't exist, so add it
            var attributes = item.baseQueryAttributes(sharedAppGroupIdentifier: sharedAppGroupIdentifier)
            attributes[kSecValueData] = valueData
            try keychainService.add(attributes: attributes as CFDictionary)
        }
    }
}

// MARK: - SharedKeychainItem+Query

private extension SharedKeychainItem {
    /// Builds the base query attributes for this keychain item as a Swift dictionary.
    ///
    /// Use this method when you need to add additional attributes to the query
    /// (e.g., `kSecReturnData`, `kSecMatchLimit`, or `kSecValueData`) before passing it to the
    /// keychain service. You can modify the returned dictionary and then cast it to `CFDictionary`
    /// when ready.
    ///
    /// - Parameter sharedAppGroupIdentifier: The shared app group identifier.
    /// - Returns: A mutable dictionary with the base query attributes.
    ///
    func baseQueryAttributes(sharedAppGroupIdentifier: String) -> [CFString: Any] {
        [
            kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
            kSecAttrAccessGroup: sharedAppGroupIdentifier,
            kSecAttrAccount: unformattedKey,
            kSecClass: kSecClassGenericPassword,
        ]
    }

    /// Builds the base query for this keychain item as a CFDictionary.
    ///
    /// Use this method when you need the query as-is without modifications. This is convenient
    /// for operations like delete or update that don't require additional attributes.
    ///
    /// - Parameter sharedAppGroupIdentifier: The shared app group identifier.
    /// - Returns: The base query as a CFDictionary.
    ///
    func baseQuery(sharedAppGroupIdentifier: String) -> CFDictionary {
        baseQueryAttributes(sharedAppGroupIdentifier: sharedAppGroupIdentifier) as CFDictionary
    }
}
