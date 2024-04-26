import Foundation

// MARK: - KeychainItem

enum KeychainItem: Equatable {
    /// The keychain item for biometrics protected user auth key.
    case biometrics(userId: String)

    /// The keychain item for a user's encryption secret key.
    case secretKey(userId: String)

    /// The `SecAccessControlCreateFlags` protection level for this keychain item.
    /// If `nil`, no extra protection is applied.
    ///
    var protection: SecAccessControlCreateFlags? {
        switch self {
        case .biometrics:
            .userPresence
        case .secretKey:
            nil
        }
    }

    /// The storage key for this keychain item.
    ///
    var unformattedKey: String {
        switch self {
        case let .biometrics(userId: id):
            "biometric_key_" + id
        case let .secretKey(userId):
            "secretKey_\(userId)"
        }
    }
}

// MARK: - KeychainRepository

protocol KeychainRepository: AnyObject {
    /// Attempts to delete the userAuthKey from the keychain.
    ///
    /// - Parameter item: The KeychainItem to be deleted.
    ///
    func deleteUserAuthKey(for item: KeychainItem) async throws

    /// Gets the stored secret key for a user from the keychain.
    ///
    /// - Parameters:
    ///   - userId: The user ID associated with the stored secret key.
    /// - Returns: The user's secret key.
    ///
    func getSecretKey(userId: String) async throws -> String

    /// Gets a user auth key value.
    ///
    /// - Parameter item: The storage key of the user auth key.
    /// - Returns: A string representing the user auth key.
    ///
    func getUserAuthKeyValue(for item: KeychainItem) async throws -> String

    /// Stores the secret key for a user in the keychain
    ///
    /// - Parameters:
    ///   - value: The secret key to store.
    ///   - userId: The user's ID
    ///
    func setSecretKey(_ value: String, userId: String) async throws

    /// Sets a user auth key/value pair.
    ///
    /// - Parameters:
    ///    - item: The storage key for this auth key.
    ///    - value: A `String` representing the user auth key.
    ///
    func setUserAuthKey(for item: KeychainItem, value: String) async throws
}

extension KeychainRepository {
    /// The format for storing the `unformattedKey` of a `KeychainItem`.
    /// The first value should be a unique appID from the `appIdService`.
    /// The second value is the `unformattedKey`
    ///
    /// Example: `bwKeyChainStorage:1234567890:biometric_key_98765`
    ///
    var storageKeyFormat: String { "bwaKeychainStorage:%@:%@" }
}

// MARK: - DefaultKeychainRepository

class DefaultKeychainRepository: KeychainRepository {
    // MARK: Properties

    /// A service used to provide unique app ids.
    ///
    let appIdService: AppIdService

    /// An identifier for this application and extensions.
    ///   ie: "LTZ2PFU5D6.com.8bit.bitwarden"
    ///
    var appSecAttrService: String {
        Bundle.main.appIdentifier
    }

    /// An identifier for this application group and extensions
    ///   ie: "group.LTZ2PFU5D6.com.8bit.bitwarden"
    ///
    var appSecAttrAccessGroup: String {
        Bundle.main.groupIdentifier
    }

    /// The keychain service used by the repository
    ///
    let keychainService: KeychainService

    // MARK: Initialization

    init(
        appIdService: AppIdService,
        keychainService: KeychainService
    ) {
        self.appIdService = appIdService
        self.keychainService = keychainService
    }

    // MARK: Methods

    /// Generates a formatted storage key for a keychain item.
    ///
    /// - Parameter item: The keychain item that needs a formatted key.
    /// - Returns: A formatted storage key.
    ///
    func formattedKey(for item: KeychainItem) async -> String {
        let appId = await appIdService.getOrCreateAppId()
        return String(format: storageKeyFormat, appId, item.unformattedKey)
    }

    /// Gets the value associated with the keychain item from the keychain.
    ///
    /// - Parameter item: The keychain item used to fetch the associated value.
    /// - Returns: The fetched value associated with the keychain item.
    ///
    func getValue(for item: KeychainItem) async throws -> String {
        let foundItem = try await keychainService.search(
            query: keychainQueryValues(
                for: item,
                adding: [
                    kSecMatchLimit: kSecMatchLimitOne,
                    kSecReturnData: true,
                    kSecReturnAttributes: true,
                ]
            )
        )

        if let resultDictionary = foundItem as? [String: Any],
           let data = resultDictionary[kSecValueData as String] as? Data {
            let string = String(decoding: data, as: UTF8.self)
            guard !string.isEmpty else {
                throw KeychainServiceError.keyNotFound(item)
            }
            return string
        }

        throw KeychainServiceError.keyNotFound(item)
    }

    /// The core key/value pairs for Keychain operations
    ///
    /// - Parameter item: The `KeychainItem` to be queried.
    ///
    func keychainQueryValues(
        for item: KeychainItem,
        adding additionalPairs: [CFString: Any] = [:]
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

    /// Sets a value associated with a keychain item in the keychain.
    ///
    /// - Parameters:
    ///   - value: The value associated with the keychain item to set.
    ///   - item: The keychain item used to set the associated value.
    ///
    func setValue(_ value: String, for item: KeychainItem) async throws {
        let accessControl = try keychainService.accessControl(
            for: item.protection ?? []
        )
        let query = await keychainQueryValues(
            for: item,
            adding: [
                kSecAttrAccessControl: accessControl as Any,
                kSecValueData: Data(value.utf8),
            ]
        )

        // Delete the previous secret, if it exists,
        //  otherwise we get `errSecDuplicateItem`.
        try? keychainService.delete(query: query)

        // Add the new key.
        try keychainService.add(
            attributes: query
        )
    }
}

extension DefaultKeychainRepository {
    func deleteUserAuthKey(for item: KeychainItem) async throws {
        try await keychainService.delete(
            query: keychainQueryValues(for: item)
        )
    }

    func getSecretKey(userId: String) async throws -> String {
        try await getValue(for: .secretKey(userId: userId))
    }

    func getUserAuthKeyValue(for item: KeychainItem) async throws -> String {
        try await getValue(for: item)
    }

    func setSecretKey(_ value: String, userId: String) async throws {
        try await setValue(value, for: .secretKey(userId: userId))
    }

    func setUserAuthKey(for item: KeychainItem, value: String) async throws {
        try await setValue(value, for: item)
    }
}
