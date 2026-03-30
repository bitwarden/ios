import BitwardenKit
import Foundation

// MARK: - KeychainItem

enum AuthenticatorKeychainItem: Equatable, KeychainItem {
    /// The keychain item for biometrics protected user auth key.
    case biometrics(userId: String)

    /// The keychain item for a user's encryption secret key.
    case secretKey(userId: String)

    /// The `SecAccessControlCreateFlags` protection level for this keychain item.
    /// If `nil`, no extra protection is applied.
    ///
    var accessControlFlags: SecAccessControlCreateFlags? {
        switch self {
        case .biometrics:
            .userPresence
        case .secretKey:
            nil
        }
    }

    var protection: CFTypeRef { kSecAttrAccessibleWhenUnlockedThisDeviceOnly }

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
    func deleteUserAuthKey(for item: AuthenticatorKeychainItem) async throws

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
    func getUserAuthKeyValue(for item: AuthenticatorKeychainItem) async throws -> String

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
    func setUserAuthKey(for item: AuthenticatorKeychainItem, value: String) async throws
}

// MARK: - DefaultKeychainRepository

class DefaultKeychainRepository: KeychainRepository {
    // MARK: Properties

    /// The keychain service facade used by the repository.
    ///
    let keychainServiceFacade: KeychainServiceFacade

    // MARK: Initialization

    init(keychainServiceFacade: KeychainServiceFacade) {
        self.keychainServiceFacade = keychainServiceFacade
    }
}

extension DefaultKeychainRepository {
    func deleteUserAuthKey(for item: AuthenticatorKeychainItem) async throws {
        try await keychainServiceFacade.deleteValue(for: item)
    }

    func getSecretKey(userId: String) async throws -> String {
        try await keychainServiceFacade.getValue(for: AuthenticatorKeychainItem.secretKey(userId: userId))
    }

    func getUserAuthKeyValue(for item: AuthenticatorKeychainItem) async throws -> String {
        try await keychainServiceFacade.getValue(for: item)
    }

    func setSecretKey(_ value: String, userId: String) async throws {
        try await keychainServiceFacade.setValue(value, for: AuthenticatorKeychainItem.secretKey(userId: userId))
    }

    func setUserAuthKey(for item: AuthenticatorKeychainItem, value: String) async throws {
        try await keychainServiceFacade.setValue(value, for: item)
    }
}

// MARK: BiometricsKeychainRepository

extension DefaultKeychainRepository: BiometricsKeychainRepository {
    func deleteUserBiometricAuthKey(userId: String) async throws {
        try await keychainServiceFacade.deleteValue(for: AuthenticatorKeychainItem.biometrics(userId: userId))
    }

    func getUserBiometricAuthKey(userId: String) async throws -> String {
        try await keychainServiceFacade.getValue(for: AuthenticatorKeychainItem.biometrics(userId: userId))
    }

    func setUserBiometricAuthKey(userId: String, value: String) async throws {
        try await keychainServiceFacade.setValue(value, for: AuthenticatorKeychainItem.biometrics(userId: userId))
    }
}
