import Foundation

// MARK: - KeychainItem

enum KeychainItem: Equatable {
    /// The keychain item for biometrics protected user auth key.
    case biometrics(userId: String)

    /// The keychain item for the neverLock user auth key.
    case neverLock(userId: String)

    /// The `SecAccessControlCreateFlags` protection level for this keychain item.
    ///     If `nil`, no extra protection is applied.
    ///
    var protection: SecAccessControlCreateFlags? {
        switch self {
        case .biometrics:
            .biometryCurrentSet
        case .neverLock:
            nil
        }
    }

    /// The storage key for this keychain item.
    ///
    var unformattedKey: String {
        switch self {
        case let .biometrics(userId: id):
            "biometric_key_" + id
        case let .neverLock(userId: id):
            "userKeyAutoUnlock_" + id
        }
    }
}

// MARK: - KeychainService

protocol KeychainService: AnyObject {
    /// Attempts to delete the userAuthKey from the keychain.
    ///
    /// - Parameter item: The KeychainItem to be deleted.
    ///
    func deleteUserAuthKey(for item: KeychainItem) async throws

    /// Gets a user auth key value.
    ///
    /// - Parameter item: The storage key of the user auth key.
    /// - Returns: A string representing the user auth key.
    ///
    func getUserAuthKeyValue(for item: KeychainItem) async throws -> String

    /// Sets a user auth key/value pair.
    ///
    /// - Parameters:
    ///     - item: The storage key for this auth key.
    ///     - value: A `String` representing the user auth key.
    ///
    func setUserAuthKey(for item: KeychainItem, value: String) async throws
}

extension KeychainService {
    /// The format for storing a `KeychainItem`'s `unformattedKey`.
    ///  The first value should be a unique appID from the `appIdService`.
    ///  The second value is the `unformattedKey`
    ///
    ///  example: `bwKeyChainStorage:1234567890:biometric_key_98765`
    ///
    var storageKeyFormat: String { "bwKeyChainStorage:%@:%@" }
}

// MARK: - KeychainServiceError

enum KeychainServiceError: Error, Equatable {
    /// When a `KeychainService` is unable to locate an auth key for a given storage key.
    ///
    /// - Parameter KeychainItem: The potential storage key for the auth key.
    ///
    case keyNotFound(KeychainItem)

    /// A passthrough for OSService Error cases.
    ///
    /// - Parameter OSStatus: The `OSStatus` returned from a keychain operation.
    ///
    case osStatusError(OSStatus)
}

// MARK: - DefaultKeychainService

class DefaultKeychainService: KeychainService {
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

    // MARK: Initialization

    init(appIdService: AppIdService) {
        self.appIdService = appIdService
    }

    // MARK: Methods

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

        // Add the addional key value pairs.
        additionalPairs.forEach { key, value in
            result[key] = value
        }

        return result as CFDictionary
    }

    func deleteUserAuthKey(for item: KeychainItem) async throws {
        let queryDictionary = await keychainQueryValues(for: item)

        let deleteStatus = SecItemDelete(queryDictionary)
        if deleteStatus == errSecItemNotFound {
            throw KeychainServiceError.keyNotFound(item)
        }
        if deleteStatus != errSecSuccess {
            throw KeychainServiceError.osStatusError(deleteStatus)
        }
    }

    func formattedKey(for item: KeychainItem) async -> String {
        let appId = await appIdService.getOrCreateAppId()
        return String(format: storageKeyFormat, appId, item.unformattedKey)
    }

    func getUserAuthKeyValue(for item: KeychainItem) async throws -> String {
        let searchQuery = await keychainQueryValues(
            for: item,
            adding: [
                kSecMatchLimit: kSecMatchLimitOne,
                kSecReturnData: true,
                kSecReturnAttributes: true,
            ]
        )

        var foundItem: AnyObject?
        let status = SecItemCopyMatching(searchQuery, &foundItem)

        if status == errSecItemNotFound {
            throw KeychainServiceError.keyNotFound(item)
        }

        if status != errSecSuccess {
            throw KeychainServiceError.osStatusError(status)
        }

        if let resultDictionary = foundItem as? [String: Any],
           let data = resultDictionary[kSecValueData as String] as? Data {
            let string = String(decoding: data, as: UTF8.self)
            return string
        }

        throw KeychainServiceError.keyNotFound(item)
    }

    func setUserAuthKey(for item: KeychainItem, value: String) async throws {
        var error: Unmanaged<CFError>?
        let accessControl = SecAccessControlCreateWithFlags(
            nil,
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            item.protection ?? [],
            &error
        )

        guard accessControl != nil,
              error == nil
        else {
            throw BiometricsServiceError.setAuthKeyFailed
        }

        let query = await keychainQueryValues(
            for: item,
            adding: [
                kSecAttrAccessControl: accessControl as Any,
                kSecValueData: Data(value.utf8),
            ]
        )

        // Try to delete the previous secret, if it exists
        // Otherwise we get `errSecDuplicateItem`
        SecItemDelete(query)

        let status = SecItemAdd(query, nil)
        guard status == errSecSuccess else {
            throw BiometricsServiceError.setAuthKeyFailed
        }
    }
}
