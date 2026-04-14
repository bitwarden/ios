import Foundation
import Security

// MARK: - KeychainServiceFacade

/// A façade layer for ``KeychainService`` that provides higher-level get, set, and delete options.
///
public protocol KeychainServiceFacade { // sourcery: AutoMockable
    // MARK: Identity

    /// Deletes the identity in the keychain for the given item.
    ///
    /// - Parameters:
    ///   - item: The keychain item to delete the associated identity.
    ///
    func deleteIdentity(for item: any KeychainItem) async throws

    /// Gets the SecIdentity associated with the keychain item.
    /// Returns `nil` if no identity exists for the given item.
    ///
    /// - Parameter item: The keychain item used to fetch the associated identity.
    /// - Returns: The fetched SecIdentity, or `nil` if not found.
    ///
    func getIdentity(for item: any KeychainItem) async throws -> SecIdentity?

    /// Stores a SecIdentity associated with a keychain item in the keychain.
    ///
    /// - Parameters:
    ///   - identity: The SecIdentity to store.
    ///   - item: The keychain item used to key the identity.
    ///
    func setIdentity(_ identity: SecIdentity, for item: any KeychainItem) async throws

    // MARK: Value

    /// Deletes the value in the keychain for the given item.
    ///
    /// - Parameters:
    ///   - item: The keychain item to delete the associated value
    ///
    func deleteValue(for item: any KeychainItem) async throws

    /// Gets the string value associated with the keychain item from the keychain.
    /// Throws `KeychainServiceError.keyNotFound` if no value exists for the given item.
    ///
    /// - Parameter item: The keychain item used to fetch the associated value.
    /// - Returns: The fetched value associated with the keychain item.
    ///
    func getValue(for item: any KeychainItem) async throws -> String

    /// Sets a value associated with a keychain item in the keychain.
    ///
    /// - Parameters:
    ///   - value: The value associated with the keychain item to set.
    ///   - item: The keychain item used to set the associated value.
    ///
    func setValue(_ value: String, for item: any KeychainItem) async throws
}

public extension KeychainServiceFacade {
    /// Gets the value associated with the keychain item from the keychain.
    /// Throws `KeychainServiceError.keyNotFound` if no value exists for the given item.
    ///
    /// - Parameter item: The keychain item used to fetch the associated value.
    /// - Returns: The fetched value associated with the keychain item.
    ///
    func getValue<T: Codable>(for item: any KeychainItem) async throws -> T {
        let string = try await getValue(for: item)

        guard let jsonData = string.data(using: .utf8) else {
            throw BitwardenError.dataError("JSON string contains invalid UTF-8 encoding.")
        }

        return try JSONDecoder.defaultDecoder.decode(T.self, from: jsonData)
    }

    /// Sets a value associated with a keychain item in the keychain.
    ///
    /// - Parameters:
    ///   - value: The value associated with the keychain item to set.
    ///   - item: The keychain item used to set the associated value.
    ///
    func setValue<T: Codable>(_ value: T, for item: any KeychainItem) async throws {
        let jsonData = try JSONEncoder.defaultEncoder.encode(value)
        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
            throw BitwardenError.dataError("JSON data is not valid.")
        }
        try await setValue(jsonString, for: item)
    }

    /// Sets an optional value associated with a keychain item in the keychain.
    /// If `value` is `nil`, the keychain item is deleted instead.
    ///
    /// - Parameters:
    ///   - value: The value associated with the keychain item to set, or `nil` to delete.
    ///   - item: The keychain item used to set the associated value.
    ///
    func setValue<T: Codable>(_ value: T?, for item: any KeychainItem) async throws {
        if let value {
            try await setValue(value, for: item)
        } else {
            try await deleteValue(for: item)
        }
    }
}

// MARK: - KeychainNamespacing

/// Defines whether keychain items are namespaced per app install or shared between apps.
///
public enum KeychainNamespacing {
    /// Items are namespaced with a per-install app ID and scoped to a `kSecAttrService`,
    /// preventing collisions with other apps sharing the same access group.
    ///
    /// - Parameters:
    ///   - appIDService: A service used to provide the per-install app ID.
    ///   - appSecAttrService: An identifier for the keychain service used by the application and extensions.
    ///                        (e.g., "com.8bit.bitwarden").
    ///   - storageKeyPrefix: A prefix used for storage keys to namespace keychain items.
    ///
    case appScoped(appIDService: AppIDService, appSecAttrService: String, storageKeyPrefix: String)

    /// Items are stored with a bare key and no `kSecAttrService`, allowing cross-app access.
    ///
    case shared
}

// MARK: - DefaultKeychainServiceFacade

/// Default implementation of ``KeychainServiceFacade``.
///
public class DefaultKeychainServiceFacade: KeychainServiceFacade {
    // MARK: Properties

    /// An identifier for the keychain access group used by the application group and extensions.
    ///
    /// Example: `LTZ2PFU5D6.com.8bit.bitwarden`
    ///
    let appSecAttrAccessGroup: String

    /// The keychain service used by the repository
    ///
    let keychainService: KeychainService

    /// Determines how keychain item keys are constructed from the unformatted key
    /// and whether `kSecAttrService` is included in the keychain entry.
    ///
    let namespacing: KeychainNamespacing

    // MARK: Initialization

    /// Creates a new instance of the keychain service façade.
    ///
    /// - Parameters:
    ///   - appSecAttrAccessGroup: An identifier for the keychain access group used by the application
    ///                            group and extensions (e.g., "LTZ2PFU5D6.com.8bit.bitwarden").
    ///   - keychainService: The keychain service used by the repository.
    ///   - namespacing: Determines how keychain item keys are constructed.
    ///
    public init(
        appSecAttrAccessGroup: String,
        keychainService: KeychainService,
        namespacing: KeychainNamespacing,
    ) {
        self.appSecAttrAccessGroup = appSecAttrAccessGroup
        self.keychainService = keychainService
        self.namespacing = namespacing
    }

    // MARK: Identity Methods

    public func deleteIdentity(for item: any KeychainItem) async throws {
        let keyLabel = await formattedKey(for: item)

        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassIdentity,
            kSecAttrLabel as String: keyLabel,
            kSecAttrAccessGroup as String: appSecAttrAccessGroup,
        ]

        try keychainService.delete(query: deleteQuery as CFDictionary)
    }

    public func getIdentity(for item: any KeychainItem) async throws -> SecIdentity? {
        let keyLabel = await formattedKey(for: item)

        let query: [String: Any] = [
            kSecClass as String: kSecClassIdentity,
            kSecAttrLabel as String: keyLabel,
            kSecAttrAccessGroup as String: appSecAttrAccessGroup,
            kSecReturnRef as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        do {
            let foundItem = try keychainService.search(query: query as CFDictionary)
            // CF types are weird, and we can't do a simple `as? SecIdentity` here, unfortunately.
            // So we can verify with CFGetTypeID and then force cast.
            guard let foundItem,
                  CFGetTypeID(foundItem as CFTypeRef) == SecIdentityGetTypeID() else { return nil }
            // swiftlint:disable:next force_cast
            return (foundItem as! SecIdentity)
        } catch KeychainServiceError.osStatusError(errSecItemNotFound) {
            return nil
        }
    }

    public func setIdentity(_ identity: SecIdentity, for item: any KeychainItem) async throws {
        let keyLabel = await formattedKey(for: item)

        let addAttributes: [String: Any] = [
            kSecClass as String: kSecClassIdentity,
            kSecValueRef as String: identity,
            kSecAttrLabel as String: keyLabel,
            kSecAttrAccessible as String: item.protection,
            kSecAttrAccessGroup as String: appSecAttrAccessGroup,
        ]

        try keychainService.add(attributes: addAttributes as CFDictionary)
    }

    // MARK: Value

    public func deleteValue(for item: any KeychainItem) async throws {
        try await keychainService.delete(
            query: keychainQueryValues(for: item),
        )
    }

    public func getValue(for item: any KeychainItem) async throws -> String {
        let foundItem = try await keychainService.search(
            query: keychainQueryValues(
                for: item,
                adding: [
                    kSecMatchLimit: kSecMatchLimitOne,
                    kSecReturnData: true,
                    kSecReturnAttributes: true,
                ],
            ),
        )

        guard let resultDictionary = foundItem as? [String: Any],
              let data = resultDictionary[kSecValueData as String] as? Data,
              let string = String(data: data, encoding: .utf8),
              !string.isEmpty else {
            throw KeychainServiceError.keyNotFound(item)
        }

        return string
    }

    public func setValue(_ value: String, for item: any KeychainItem) async throws {
        let accessControl = try keychainService.accessControl(
            protection: item.protection,
            for: item.accessControlFlags ?? [],
        )
        let baseQuery = await keychainQueryValues(for: item)
        let updateAttributes: CFDictionary = [
            kSecAttrAccessControl: accessControl as Any,
            kSecValueData: Data(value.utf8),
        ] as CFDictionary

        do {
            // Try to update first - if item exists, this avoids delete-then-add race condition
            try keychainService.update(query: baseQuery, attributes: updateAttributes)
        } catch KeychainServiceError.osStatusError(errSecItemNotFound) {
            // Item doesn't exist, so add it
            let addAttributes = await keychainQueryValues(
                for: item,
                adding: [
                    kSecAttrAccessControl: accessControl as Any,
                    kSecValueData: Data(value.utf8),
                ],
            )
            try keychainService.add(attributes: addAttributes)
        }
    }

    // MARK: Private Methods

    /// Generates a formatted storage key for a keychain item.
    ///
    /// - Parameter item: The keychain item that needs a formatted key.
    /// - Returns: A formatted storage key.
    ///
    func formattedKey(for item: any KeychainItem) async -> String {
        switch namespacing {
        case let .appScoped(appIDService, _, storageKeyPrefix):
            let appId = await appIDService.getOrCreateAppID()
            // Generate a storage key for storing a keychain item in an app-scoped keychain
            return String(format: "\(storageKeyPrefix):%@:%@", appId, item.unformattedKey)
        case .shared:
            // For historical reasons, shared-keychain items use the plain unformatted key.
            return item.unformattedKey
        }
    }

    /// The core key/value pairs for keychain operations.
    ///
    /// cf. https://developer.apple.com/documentation/security/searching-for-keychain-items
    ///
    /// - Parameter item: The keychain item to be queried.
    ///
    func keychainQueryValues(
        for item: any KeychainItem,
        adding additionalPairs: [CFString: Any] = [:],
    ) async -> CFDictionary {
        // Prepare a formatted `kSecAttrAccount` value.
        let formattedSecAttrAccount = await formattedKey(for: item)

        // Configure the base dictionary
        var result: [CFString: Any] = [
            kSecAttrAccount: formattedSecAttrAccount,
            kSecAttrAccessGroup: appSecAttrAccessGroup,
            kSecClass: kSecClassGenericPassword,
        ]

        // For historical reasons, shared-keychain items don't have a kSecAttrService.
        if case let .appScoped(_, appSecAttrService, _) = namespacing {
            result[kSecAttrService] = appSecAttrService
        }

        // Add the additional key value pairs.
        additionalPairs.forEach { key, value in
            result[key] = value
        }

        return result as CFDictionary
    }
}
