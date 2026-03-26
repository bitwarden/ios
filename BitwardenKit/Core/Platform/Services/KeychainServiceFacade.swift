import Foundation

// MARK: - KeychainServiceFacade

/// A façade layer for ``KeychainService`` that provides higher-level get, set, and delete options.
///
public protocol KeychainServiceFacade { // sourcery: AutoMockable
    /// Deletes the value in the keychain for the given item.
    ///
    /// - Parameters:
    ///   - item: The keychain item to delete the associated value
    ///
    func deleteValue(for item: any KeychainItem) async throws

    /// Gets the string value associated with the keychain item from the keychain.
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
    func setValue<T: Codable>(_ value: T, for item: any KeychainItem) async throws  {
        let jsonData = try JSONEncoder.defaultEncoder.encode(value)
        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
            throw BitwardenError.dataError("JSON data is not valid.")
        }
        try await setValue(jsonString, for: item)
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
    ///
    case appScoped(appIDService: AppIDService, appSecAttrService: String)

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
    var appSecAttrAccessGroup: String

    /// The keychain service used by the repository
    ///
    let keychainService: KeychainService

    /// Determines how keychain item keys are constructed from the unformatted key
    /// and whether `kSecAttrService` is included in the keychain entry.
    ///
    let namespacing: KeychainNamespacing

    /// A prefix used for storage keys to namespace keychain items.
    ///
    let storageKeyPrefix: String

    // MARK: Computed Properties

    /// The format string used to generate a storage key for storing a keychain item in an app-scoped keychain.
    /// The first value should be the app ID from the `appIDService`.
    /// The second value should be the item's `unformattedKey`.
    ///
    /// example: `bwKeyChainStorage:1234567890:biometric_key_98765`
    ///
    var storageKeyFormat: String { "\(storageKeyPrefix):%@:%@" }

    // MARK: Initialization

    /// Creates a new instance of the keychain service façade.
    ///
    /// - Parameters:
    ///   - appSecAttrAccessGroup: An identifier for the keychain access group used by the application
    ///                            group and extensions (e.g., "LTZ2PFU5D6.com.8bit.bitwarden").
    ///   - keychainService: The keychain service used by the repository.
    ///   - namespacing: Determines how keychain item keys are constructed.
    ///   - storageKeyPrefix: A prefix used for storage keys to namespace keychain items.
    ///
    public init(
        appSecAttrAccessGroup: String,
        keychainService: KeychainService,
        namespacing: KeychainNamespacing,
        storageKeyPrefix: String,
    ) {
        self.appSecAttrAccessGroup = appSecAttrAccessGroup
        self.keychainService = keychainService
        self.namespacing = namespacing
        self.storageKeyPrefix = storageKeyPrefix
    }

    // MARK: Methods

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

        if let resultDictionary = foundItem as? [String: Any],
           let data = resultDictionary[kSecValueData as String] as? Data,
           let string = String(data: data, encoding: .utf8) {
            guard !string.isEmpty else {
                throw KeychainServiceError.keyNotFound(item)
            }
            return string
        }

        throw KeychainServiceError.keyNotFound(item)
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
        case let .appScoped(appIDService, _):
            let appId = await appIDService.getOrCreateAppID()
            return String(format: storageKeyFormat, appId, item.unformattedKey)
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
        if case let .appScoped(_, appSecAttrService) = namespacing {
            result[kSecAttrService] = appSecAttrService
        }

        // Add the additional key value pairs.
        additionalPairs.forEach { key, value in
            result[key] = value
        }

        return result as CFDictionary
    }
}
