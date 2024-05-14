import Foundation

// MARK: - KeychainItem

enum KeychainItem: Equatable {
    /// The keychain item for a user's access token.
    case accessToken(userId: String)

    /// The keychain item for biometrics protected user auth key.
    case biometrics(userId: String)

    /// The keychain item for device key.
    case deviceKey(userId: String)

    /// The keychain item for the neverLock user auth key.
    case neverLock(userId: String)

    /// The keychain item for a user's pending login request.
    case pendingAdminLoginRequest(userId: String)

    /// The keychain item for a user's refresh token.
    case refreshToken(userId: String)

    /// The `SecAccessControlCreateFlags` protection level for this keychain item.
    ///     If `nil`, no extra protection is applied.
    ///
    var protection: SecAccessControlCreateFlags? {
        switch self {
        case .accessToken,
             .deviceKey,
             .neverLock,
             .pendingAdminLoginRequest,
             .refreshToken:
            nil
        case .biometrics:
            .biometryCurrentSet
        }
    }

    /// The storage key for this keychain item.
    ///
    var unformattedKey: String {
        switch self {
        case let .accessToken(userId):
            "accessToken_\(userId)"
        case let .biometrics(userId: id):
            "biometric_key_" + id
        case let .deviceKey(userId: id):
            "deviceKey_" + id
        case let .neverLock(userId: id):
            "userKeyAutoUnlock_" + id
        case let .pendingAdminLoginRequest(userId):
            "pendingAdminLoginRequest_\(userId)"
        case let .refreshToken(userId):
            "refreshToken_\(userId)"
        }
    }
}

// MARK: - KeychainRepository

protocol KeychainRepository: AnyObject {
    /// Deletes all items stored in the keychain.
    ///
    func deleteAllItems() async throws

    /// Deletes items stored in the keychain for a specific user.
    ///
    /// - Parameter userId: The user ID associated with the keychain items to delete.
    ///
    func deleteItems(for userId: String) async throws

    /// Attempts to delete the userAuthKey from the keychain.
    ///
    /// - Parameter item: The KeychainItem to be deleted.
    ///
    func deleteUserAuthKey(for item: KeychainItem) async throws

    /// Attempts to delete the device key from the keychain.
    ///
    /// - Parameter userId: The user ID associated with the stored device key.
    ///
    func deleteDeviceKey(userId: String) async throws

    /// Attempts to delete the pending admin login request from the keychain.
    ///
    /// - Parameter userId: The user ID associated with the stored device key.
    ///
    func deletePendingAdminLoginRequest(userId: String) async throws

    /// Gets the stored access token for a user from the keychain.
    ///
    /// - Parameter userId: The user ID associated with the stored access token.
    /// - Returns: The user's access token.
    ///
    func getAccessToken(userId: String) async throws -> String

    /// Gets the stored device key for a user from the keychain.
    ///
    /// - Parameter userId: The user ID associated with the stored device key.
    /// - Returns: The device key.
    ///
    func getDeviceKey(userId: String) async throws -> String?

    /// Gets the stored refresh token for a user from the keychain.
    ///
    /// - Parameter userId: The user ID associated with the stored refresh token.
    /// - Returns: The user's refresh token.
    ///
    func getRefreshToken(userId: String) async throws -> String

    /// Gets the pending admin login request for a user ID.
    ///
    /// - Parameter userId: The user ID associated with the pending admin login request.
    /// - Returns: The pending admin login request.
    ///
    func getPendingAdminLoginRequest(userId: String) async throws -> String?

    /// Gets a user auth key value.
    ///
    /// - Parameter item: The storage key of the user auth key.
    /// - Returns: A string representing the user auth key.
    ///
    func getUserAuthKeyValue(for item: KeychainItem) async throws -> String

    /// Stores the access token for a user in the keychain.
    ///
    /// - Parameters:
    ///   - value: The access token to store.
    ///   - userId: The user's ID, used to get back the token later on.
    ///
    func setAccessToken(_ value: String, userId: String) async throws

    /// Stores the device key for a user in the keychain.
    ///
    /// - Parameters:
    ///   - value: The device key to store.
    ///   - userId: The user's ID, used to get back the device key later on.
    ///
    func setDeviceKey(_ value: String, userId: String) async throws

    /// Stores the refresh token for a user in the keychain.
    ///
    /// - Parameters:
    ///   - value: The refresh token to store.
    ///   - userId: The user's ID, used to get back the token later on.
    ///
    func setRefreshToken(_ value: String, userId: String) async throws

    /// Sets the pending admin login request for a user ID.
    ///
    /// - Parameters:
    ///   - adminLoginRequest: The user's pending admin login request.
    ///   - userId: The user ID associated with the pending admin login request.
    ///
    func setPendingAdminLoginRequest(_ value: String, userId: String) async throws

    /// Sets a user auth key/value pair.
    ///
    /// - Parameters:
    ///    - item: The storage key for this auth key.
    ///    - value: A `String` representing the user auth key.
    ///
    func setUserAuthKey(for item: KeychainItem, value: String) async throws
}

extension KeychainRepository {
    /// The format for storing a `KeychainItem`'s `unformattedKey`.
    ///  The first value should be a unique appID from the `appIdService`.
    ///  The second value is the `unformattedKey`
    ///
    ///  example: `bwKeyChainStorage:1234567890:biometric_key_98765`
    ///
    var storageKeyFormat: String { "bwKeyChainStorage:%@:%@" }
}

// MARK: - DefaultKeychainRepository

class DefaultKeychainRepository: KeychainRepository {
    // MARK: Properties

    /// A service used to provide unique app ids.
    ///
    let appIdService: AppIdService

    /// An identifier for the keychain service used by the application and extensions.
    ///
    /// Example: "com.8bit.bitwarden".
    ///
    var appSecAttrService: String {
        Bundle.main.appIdentifier
    }

    /// An identifier for the keychain access group used by the application group and extensions.
    ///
    /// Example: "LTZ2PFU5D6.com.8bit.bitwarden"
    ///
    var appSecAttrAccessGroup: String {
        Bundle.main.keychainAccessGroup
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

    /// The core key/value pairs for Keychain operations.
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
    func deleteAllItems() async throws {
        let itemClasses = [
            kSecClassGenericPassword,
            kSecClassInternetPassword,
            kSecClassCertificate,
            kSecClassKey,
            kSecClassIdentity,
        ]
        for itemClass in itemClasses {
            try keychainService.delete(query: [kSecClass: itemClass] as CFDictionary)
        }
    }

    func deleteItems(for userId: String) async throws {
        let keychainItems: [KeychainItem] = [
            .accessToken(userId: userId),
            .biometrics(userId: userId),
            // Exclude `deviceKey` since it is used to log back into an account.
            .neverLock(userId: userId),
            .pendingAdminLoginRequest(userId: userId),
            .refreshToken(userId: userId),
        ]
        for keychainItem in keychainItems {
            try await keychainService.delete(query: keychainQueryValues(for: keychainItem))
        }
    }

    func deleteUserAuthKey(for item: KeychainItem) async throws {
        try await keychainService.delete(
            query: keychainQueryValues(for: item)
        )
    }

    func deleteDeviceKey(userId: String) async throws {
        try await keychainService.delete(
            query: keychainQueryValues(for: .deviceKey(userId: userId))
        )
    }

    func deletePendingAdminLoginRequest(userId: String) async throws {
        try await keychainService.delete(
            query: keychainQueryValues(for: .pendingAdminLoginRequest(userId: userId))
        )
    }

    func getAccessToken(userId: String) async throws -> String {
        try await getValue(for: .accessToken(userId: userId))
    }

    func getDeviceKey(userId: String) async throws -> String? {
        try await getValue(for: .deviceKey(userId: userId))
    }

    func getRefreshToken(userId: String) async throws -> String {
        try await getValue(for: .refreshToken(userId: userId))
    }

    func getPendingAdminLoginRequest(userId: String) async throws -> String? {
        try await getValue(for: .pendingAdminLoginRequest(userId: userId))
    }

    func getUserAuthKeyValue(for item: KeychainItem) async throws -> String {
        try await getValue(for: item)
    }

    func setAccessToken(_ value: String, userId: String) async throws {
        try await setValue(value, for: .accessToken(userId: userId))
    }

    func setDeviceKey(_ value: String, userId: String) async throws {
        try await setValue(value, for: .deviceKey(userId: userId))
    }

    func setRefreshToken(_ value: String, userId: String) async throws {
        try await setValue(value, for: .refreshToken(userId: userId))
    }

    func setPendingAdminLoginRequest(_ value: String, userId: String) async throws {
        try await setValue(value, for: .pendingAdminLoginRequest(userId: userId))
    }

    func setUserAuthKey(for item: KeychainItem, value: String) async throws {
        try await setValue(value, for: item)
    }
}
