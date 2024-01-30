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
    var storageKey: String {
        switch self {
        case let .biometrics(userId: id):
            "biometric_key_\(id)"
        case let .neverLock(userId: id):
            "userKeyAutoUnlock_\(id)"
        }
    }

    /// The value to provide for the `kSecAttrService` key.
    var service: String {
        "com.8bit.bitwarden.watch.kc"
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
    // MARK: Methods

    func deleteUserAuthKey(for item: KeychainItem) async throws {
        let queryDictionary = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: item.service,
            kSecAttrAccount: item.storageKey,
        ] as CFDictionary

        let deleteStatus = SecItemDelete(queryDictionary)
        if deleteStatus == errSecItemNotFound {
            throw KeychainServiceError.keyNotFound(item)
        }
        if deleteStatus != errSecSuccess {
            throw KeychainServiceError.osStatusError(deleteStatus)
        }
    }

    func getUserAuthKeyValue(for item: KeychainItem) async throws -> String {
        let searchQuery = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: item.service,
            kSecAttrAccount: item.storageKey,
            kSecMatchLimit: kSecMatchLimitOne,
            kSecReturnData: true,
            kSecReturnAttributes: true,
        ] as CFDictionary

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

        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: item.service,
            kSecAttrAccount: item.storageKey,
            kSecValueData: Data(value.utf8),
            kSecAttrAccessControl: accessControl as Any,
        ] as CFDictionary

        // Try to delete the previous secret, if it exists
        // Otherwise we get `errSecDuplicateItem`
        SecItemDelete(query)

        let status = SecItemAdd(query, nil)
        guard status == errSecSuccess else {
            throw BiometricsServiceError.setAuthKeyFailed
        }
    }
}
