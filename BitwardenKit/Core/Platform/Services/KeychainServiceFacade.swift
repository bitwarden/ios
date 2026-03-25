import Foundation

// MARK: - KeychainServiceFacade

/// A façade layer for ``KeychainService`` that provides higher-level get, set, and delete options.
///
public protocol KeychainServiceFacade { // sourcery: AutoMockable
    /// Gets the string value associated with the keychain item from the keychain.
    ///
    /// - Parameter item: The keychain item used to fetch the associated value.
    /// - Returns: The fetched value associated with the keychain item.
    ///
    func getValue(for item: any KeychainItem) async throws -> String
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
}

// MARK: - DefaultKeychainServiceFacade

/// Default implementation of ``KeychainServiceFacade``.
///
public class DefaultKeychainServiceFacade: KeychainServiceFacade {
    // MARK: Properties

    /// A service used to provide the app ID.
    ///
    let appIDService: AppIDService

    /// An identifier for the keychain service used by the application and extensions.
    ///
    /// Example: "com.8bit.bitwarden".
    ///
    var appSecAttrService: String

    /// An identifier for the keychain access group used by the application group and extensions.
    ///
    /// Example: "LTZ2PFU5D6.com.8bit.bitwarden"
    ///
    var appSecAttrAccessGroup: String

    /// The keychain service used by the repository
    ///
    let keychainService: KeychainService

    /// A prefix used for storage keys to namespace keychain items.
    ///
    let storageKeyPrefix: String

    // MARK: Computed Properties

    /// The format string used to generate a storage key for storing a keychain item.
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
    ///   - appIDService: A service used to provide the app ID.
    ///   - appSecAttrAccessGroup: An identifier for the keychain access group used by the application
    ///                            group and extensions (e.g., "LTZ2PFU5D6.com.8bit.bitwarden").
    ///   - appSecAttrService: An identifier for the keychain service used by the application and
    ///                        extensions (e.g., "com.8bit.bitwarden").
    ///   - keychainService: The keychain service used by the repository.
    ///   - storageKeyPrefix: A prefix used for storage keys to namespace keychain items.
    ///
    public init(
        appIDService: AppIDService,
        appSecAttrAccessGroup: String,
        appSecAttrService: String,
        keychainService: KeychainService,
        storageKeyPrefix: String,
    ) {
        self.appIDService = appIDService
        self.appSecAttrAccessGroup = appSecAttrAccessGroup
        self.appSecAttrService = appSecAttrService
        self.keychainService = keychainService
        self.storageKeyPrefix = storageKeyPrefix
    }

    // MARK: Methods

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
        let appId = await appIDService.getOrCreateAppID()
        return String(format: storageKeyFormat, appId, item.unformattedKey)
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
            kSecAttrService: appSecAttrService,
            kSecClass: kSecClassGenericPassword,
        ]

        // Add the additional key value pairs.
        additionalPairs.forEach { key, value in
            result[key] = value
        }

        return result as CFDictionary
    }
}
