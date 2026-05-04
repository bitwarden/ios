import BitwardenKit
import BitwardenSdk
import Foundation

// MARK: - KeychainItem

// swiftlint:disable file_length
enum BitwardenKeychainItem: Equatable, KeychainItem {
    /// The keychain item for a user's access token.
    case accessToken(userId: String)

    /// The keychain item for a user's vault key for Authenticator syncing.
    case authenticatorVaultKey(userId: String)

    /// The keychain item for biometrics protected user auth key.
    case biometrics(userId: String)

    /// The keychain item for a client certificate identity (SecIdentity), keyed by certificate fingerprint.
    case clientCertificateIdentity(fingerprint: String)

    /// The keychain item for the device auth key.
    case deviceAuthKey(userId: String)

    /// The keychain item for the device auth key metadata.
    case deviceAuthKeyMetadata(userId: String)

    /// The keychain item for device key.
    case deviceKey(userId: String)

    /// The keychain item for a user's last active boot epoch.
    ///
    /// The boot epoch is `wallTime − monotonicTime` and is used to detect the reboot-timing attack.
    ///
    case lastActiveBootEpoch(userId: String)

    /// The keychain item for a user's last active time.
    case lastActiveTime(userId: String)

    /// The keychain item for a user's last active monotonic time.
    case lastActiveMonotonicTime(userId: String)

    /// The keychain item for the neverLock user auth key.
    case neverLock(userId: String)

    /// The keychain item for a user's pending login request.
    case pendingAdminLoginRequest(userId: String)

    /// The keychain item for a user's refresh token.
    case refreshToken(userId: String)

    /// The keychain item for server communication configuration for a hostname.
    case serverCommunicationConfig(hostname: String)

    /// The keychain item for the number of unsuccessful unlock attempts.
    case unsuccessfulUnlockAttempts(userId: String)

    /// The keychain item for a user's vault timeout.
    case vaultTimeout(userId: String)

    /// The `SecAccessControlCreateFlags` level for this keychain item.
    ///     If `nil`, no extra protection is applied.
    ///
    var accessControlFlags: SecAccessControlCreateFlags? {
        switch self {
        case .accessToken,
             .authenticatorVaultKey,
             .clientCertificateIdentity,
             .deviceAuthKeyMetadata,
             .deviceKey,
             .lastActiveBootEpoch,
             .lastActiveMonotonicTime,
             .lastActiveTime,
             .neverLock,
             .pendingAdminLoginRequest,
             .refreshToken,
             .serverCommunicationConfig,
             .unsuccessfulUnlockAttempts,
             .vaultTimeout:
            nil
        case .biometrics,
             .deviceAuthKey:
            .biometryCurrentSet
        }
    }

    /// The protection level for this keychain item.
    var protection: CFTypeRef {
        switch self {
        case .biometrics,
             .deviceAuthKey,
             .deviceAuthKeyMetadata,
             .deviceKey,
             .lastActiveBootEpoch,
             .lastActiveMonotonicTime,
             .lastActiveTime,
             .neverLock,
             .pendingAdminLoginRequest,
             .unsuccessfulUnlockAttempts,
             .vaultTimeout:
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        case .accessToken,
             .authenticatorVaultKey,
             .clientCertificateIdentity,
             .refreshToken,
             .serverCommunicationConfig:
            kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        }
    }

    /// The storage key for this keychain item.
    ///
    var unformattedKey: String {
        switch self {
        case let .accessToken(userId):
            "accessToken_\(userId)"
        case let .authenticatorVaultKey(userId):
            "authenticatorVaultKey_\(userId)"
        case let .biometrics(userId: id):
            "userKeyBiometricUnlock_" + id
        case let .clientCertificateIdentity(fingerprint):
            "clientCertificateIdentity_\(fingerprint)"
        case let .deviceKey(userId: id):
            "deviceKey_" + id
        case let .deviceAuthKey(userId: id):
            "deviceAuthKey_" + id
        case let .deviceAuthKeyMetadata(userId: id):
            "deviceAuthKeyMetadata_" + id
        case let .lastActiveBootEpoch(userId):
            "lastActiveBootEpoch_\(userId)"
        case let .lastActiveMonotonicTime(userId):
            "lastActiveMonotonicTime_\(userId)"
        case let .lastActiveTime(userId):
            "lastActiveTime_\(userId)"
        case let .neverLock(userId: id):
            "userKeyAutoUnlock_" + id
        case let .pendingAdminLoginRequest(userId):
            "pendingAdminLoginRequest_\(userId)"
        case let .refreshToken(userId):
            "refreshToken_\(userId)"
        case let .serverCommunicationConfig(hostname):
            "serverCommunicationConfig_\(hostname)"
        case let .unsuccessfulUnlockAttempts(userId):
            "unsuccessfulUnlockAttempts_\(userId)"
        case let .vaultTimeout(userId):
            "vaultTimeout_\(userId)"
        }
    }
}

// MARK: - KeychainRepository

protocol KeychainRepository: AnyObject, ServerCommunicationConfigKeychainRepository { // sourcery: AutoMockable
    /// Deletes all items stored in the keychain.
    ///
    func deleteAllItems() async throws

    /// Attempts to delete the authenticator vault key from the keychain.
    ///
    /// - Parameter userId: The user ID associated with the authenticator vault key.
    ///
    func deleteAuthenticatorVaultKey(userId: String) async throws

    /// Deletes the client certificate identity from the keychain by certificate fingerprint.
    ///
    /// - Parameter fingerprint: The SHA-256 fingerprint of the certificate to delete.
    func deleteClientCertificateIdentity(fingerprint: String) async throws

    /// Deletes items stored in the keychain for a specific user.
    ///
    /// - Parameter userId: The user ID associated with the keychain items to delete.
    ///
    func deleteItems(for userId: String) async throws

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

    /// Attempts to delete the userAuthKey from the keychain.
    ///
    /// - Parameter item: The KeychainItem to be deleted.
    ///
    func deleteUserAuthKey(for item: BitwardenKeychainItem) async throws

    /// Gets the stored access token for a user from the keychain.
    ///
    /// - Parameter userId: The user ID associated with the stored access token.
    /// - Returns: The user's access token.
    ///
    func getAccessToken(userId: String) async throws -> String

    /// Gets the authenticator vault key for a user ID.
    ///
    /// - Parameter userId: The user ID associated with the authenticator vault key.
    /// - Returns: The authenticator vault key.
    ///
    func getAuthenticatorVaultKey(userId: String) async throws -> String

    /// Gets the client certificate identity from the keychain by certificate fingerprint.
    ///
    /// - Parameter fingerprint: The SHA-256 fingerprint of the certificate.
    /// - Returns: The SecIdentity, or `nil` if not stored.
    ///
    func getClientCertificateIdentity(fingerprint: String) async throws -> SecIdentity?

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
    func getUserAuthKeyValue(for item: BitwardenKeychainItem) async throws -> String

    /// Stores the access token for a user in the keychain.
    ///
    /// - Parameters:
    ///   - value: The access token to store.
    ///   - userId: The user's ID, used to get back the token later on.
    ///
    func setAccessToken(_ value: String, userId: String) async throws

    /// Sets the authenticator vault key for a user ID.
    ///
    /// - Parameters:
    ///   - value: The authenticator vault key to store.
    ///   - userId: The user ID associated with the authenticator vault key.
    ///
    func setAuthenticatorVaultKey(_ value: String, userId: String) async throws

    /// Stores the client certificate identity in the keychain, keyed by certificate fingerprint.
    ///
    /// - Parameters:
    ///   - identity: The SecIdentity to store.
    ///   - fingerprint: The SHA-256 fingerprint of the certificate used as the keychain label.
    ///
    func setClientCertificateIdentity(_ identity: SecIdentity, fingerprint: String) async throws

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
    func setUserAuthKey(for item: BitwardenKeychainItem, value: String) async throws
}

// MARK: - DefaultKeychainRepository

class DefaultKeychainRepository: KeychainRepository {
    // MARK: Properties

    /// The keychain service used for bulk deletion operations not covered by the facade.
    ///
    let keychainService: KeychainService

    /// The keychain service facade used by the repository.
    ///
    let keychainServiceFacade: KeychainServiceFacade

    // MARK: Initialization

    init(
        keychainService: KeychainService,
        keychainServiceFacade: KeychainServiceFacade,
    ) {
        self.keychainService = keychainService
        self.keychainServiceFacade = keychainServiceFacade
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

    func deleteAuthenticatorVaultKey(userId: String) async throws {
        try await keychainServiceFacade.deleteValue(for: BitwardenKeychainItem.authenticatorVaultKey(userId: userId))
    }

    func deleteClientCertificateIdentity(fingerprint: String) async throws {
        try await keychainServiceFacade.deleteIdentity(
            for: BitwardenKeychainItem.clientCertificateIdentity(fingerprint: fingerprint),
        )
    }

    func deleteItems(for userId: String) async throws {
        let keychainItems: [BitwardenKeychainItem] = [
            .accessToken(userId: userId),
            .authenticatorVaultKey(userId: userId),
            .biometrics(userId: userId),
            // Exclude `deviceKey` since it is used to log back into an account.
            // Also exclude `deviceAuthKey` and `deviceAuthKeyMetadata` since they are used to log back into an account.
            .lastActiveBootEpoch(userId: userId),
            .lastActiveMonotonicTime(userId: userId),
            .lastActiveTime(userId: userId),
            .neverLock(userId: userId),
            // Exclude `pendingAdminLoginRequest` since if a TDE user is logged out before the request
            // is approved, the next login for the user will succeed with the pending request.
            .refreshToken(userId: userId),
            .unsuccessfulUnlockAttempts(userId: userId),
            // Exclude `vaultTimeout` since it should be maintained for users who log out and back in regularly.
        ]
        for keychainItem in keychainItems {
            try await keychainServiceFacade.deleteValue(for: keychainItem)
        }
    }

    func deleteDeviceKey(userId: String) async throws {
        try await keychainServiceFacade.deleteValue(for: BitwardenKeychainItem.deviceKey(userId: userId))
    }

    func deletePendingAdminLoginRequest(userId: String) async throws {
        try await keychainServiceFacade.deleteValue(
            for: BitwardenKeychainItem.pendingAdminLoginRequest(userId: userId),
        )
    }

    func deleteUserAuthKey(for item: BitwardenKeychainItem) async throws {
        try await keychainServiceFacade.deleteValue(for: item)
    }

    func getAccessToken(userId: String) async throws -> String {
        try await keychainServiceFacade.getValue(for: BitwardenKeychainItem.accessToken(userId: userId))
    }

    func getAuthenticatorVaultKey(userId: String) async throws -> String {
        try await keychainServiceFacade.getValue(for: BitwardenKeychainItem.authenticatorVaultKey(userId: userId))
    }

    func getClientCertificateIdentity(fingerprint: String) async throws -> SecIdentity? {
        try await keychainServiceFacade.getIdentity(
            for: BitwardenKeychainItem.clientCertificateIdentity(fingerprint: fingerprint),
        )
    }

    func getDeviceKey(userId: String) async throws -> String? {
        do {
            let value: String = try await keychainServiceFacade.getValue(
                for: BitwardenKeychainItem.deviceKey(userId: userId),
            )
            return value
        } catch KeychainServiceError.osStatusError(errSecItemNotFound), KeychainServiceError.keyNotFound {
            return nil
        }
    }

    func getRefreshToken(userId: String) async throws -> String {
        try await keychainServiceFacade.getValue(for: BitwardenKeychainItem.refreshToken(userId: userId))
    }

    func getPendingAdminLoginRequest(userId: String) async throws -> String? {
        do {
            let value: String = try await keychainServiceFacade.getValue(
                for: BitwardenKeychainItem.pendingAdminLoginRequest(userId: userId),
            )
            return value
        } catch KeychainServiceError.osStatusError(errSecItemNotFound), KeychainServiceError.keyNotFound {
            return nil
        }
    }

    func getUserAuthKeyValue(for item: BitwardenKeychainItem) async throws -> String {
        try await keychainServiceFacade.getValue(for: item)
    }

    func setAccessToken(_ value: String, userId: String) async throws {
        try await keychainServiceFacade.setValue(value, for: BitwardenKeychainItem.accessToken(userId: userId))
    }

    func setAuthenticatorVaultKey(_ value: String, userId: String) async throws {
        try await keychainServiceFacade.setValue(
            value,
            for: BitwardenKeychainItem.authenticatorVaultKey(userId: userId),
        )
    }

    func setClientCertificateIdentity(_ identity: SecIdentity, fingerprint: String) async throws {
        try await keychainServiceFacade.setIdentity(
            identity,
            for: BitwardenKeychainItem.clientCertificateIdentity(fingerprint: fingerprint),
        )
    }

    func setDeviceKey(_ value: String, userId: String) async throws {
        try await keychainServiceFacade.setValue(value, for: BitwardenKeychainItem.deviceKey(userId: userId))
    }

    func setRefreshToken(_ value: String, userId: String) async throws {
        try await keychainServiceFacade.setValue(value, for: BitwardenKeychainItem.refreshToken(userId: userId))
    }

    func setPendingAdminLoginRequest(_ value: String, userId: String) async throws {
        try await keychainServiceFacade.setValue(
            value,
            for: BitwardenKeychainItem.pendingAdminLoginRequest(userId: userId),
        )
    }

    func setUserAuthKey(for item: BitwardenKeychainItem, value: String) async throws {
        try await keychainServiceFacade.setValue(value, for: item)
    }
}

// MARK: BiometricsKeychainRepository

extension DefaultKeychainRepository: BiometricsKeychainRepository {
    func deleteUserBiometricAuthKey(userId: String) async throws {
        try await keychainServiceFacade.deleteValue(for: BitwardenKeychainItem.biometrics(userId: userId))
    }

    func getUserBiometricAuthKey(userId: String) async throws -> String {
        try await keychainServiceFacade.getValue(for: BitwardenKeychainItem.biometrics(userId: userId))
    }

    func setUserBiometricAuthKey(userId: String, value: String) async throws {
        try await keychainServiceFacade.setValue(value, for: BitwardenKeychainItem.biometrics(userId: userId))
    }
}

// MARK: DeviceAuthKeychainRepository

extension DefaultKeychainRepository: DeviceAuthKeychainRepository {
    func deleteDeviceAuthKey(userId: String) async throws {
        // We want to delete metadata first because that's what's used to determine if we're in a
        // consistent state.
        try await keychainServiceFacade.deleteValue(
            for: BitwardenKeychainItem.deviceAuthKeyMetadata(userId: userId),
        )
        try await keychainServiceFacade.deleteValue(for: BitwardenKeychainItem.deviceAuthKey(userId: userId))
    }

    func getDeviceAuthKey(userId: String) async throws -> DeviceAuthKeyRecord? {
        do {
            return try await keychainServiceFacade.getValue(
                for: BitwardenKeychainItem.deviceAuthKey(userId: userId),
            )
        } catch KeychainServiceError.osStatusError(errSecItemNotFound), KeychainServiceError.keyNotFound {
            return nil
        }
    }

    func getDeviceAuthKeyMetadata(userId: String) async throws -> DeviceAuthKeyMetadata? {
        do {
            return try await keychainServiceFacade.getValue(
                for: BitwardenKeychainItem.deviceAuthKeyMetadata(userId: userId),
            )
        } catch KeychainServiceError.osStatusError(errSecItemNotFound), KeychainServiceError.keyNotFound {
            return nil
        }
    }

    func setDeviceAuthKey(
        record: DeviceAuthKeyRecord,
        metadata: DeviceAuthKeyMetadata,
        userId: String,
    ) async throws {
        // We want to set metadata last because that's what's used to determine if we're in a
        // consistent state.
        try await keychainServiceFacade.setValue(record, for: BitwardenKeychainItem.deviceAuthKey(userId: userId))
        try await keychainServiceFacade.setValue(
            metadata,
            for: BitwardenKeychainItem.deviceAuthKeyMetadata(userId: userId),
        )
    }
}

// MARK: UserSessionKeychainRepository

extension DefaultKeychainRepository: UserSessionKeychainRepository {
    // MARK: Last Active Time

    func getLastActiveTime(userId: String) async throws -> Date? {
        do {
            let stored = try await keychainServiceFacade.getValue(
                for: BitwardenKeychainItem.lastActiveTime(userId: userId),
            )
            guard let timeInterval = TimeInterval(stored) else {
                return nil
            }
            return Date(timeIntervalSince1970: timeInterval)
        } catch KeychainServiceError.osStatusError(errSecItemNotFound), KeychainServiceError.keyNotFound {
            return nil
        }
    }

    func setLastActiveTime(_ date: Date?, userId: String) async throws {
        let value = date.map { String($0.timeIntervalSince1970) } ?? ""
        try await keychainServiceFacade.setValue(value, for: BitwardenKeychainItem.lastActiveTime(userId: userId))
    }

    func getLastActiveMonotonicTime(userId: String) async throws -> TimeInterval? {
        do {
            let stored = try await keychainServiceFacade.getValue(
                for: BitwardenKeychainItem.lastActiveMonotonicTime(userId: userId),
            )
            return TimeInterval(stored)
        } catch KeychainServiceError.osStatusError(errSecItemNotFound), KeychainServiceError.keyNotFound {
            return nil
        }
    }

    func setLastActiveMonotonicTime(_ monotonicTime: TimeInterval?, userId: String) async throws {
        let value = monotonicTime.map { String($0) }
        guard let value else {
            try await keychainServiceFacade.deleteValue(
                for: BitwardenKeychainItem.lastActiveMonotonicTime(userId: userId),
            )
            return
        }

        try await keychainServiceFacade.setValue(
            value,
            for: BitwardenKeychainItem.lastActiveMonotonicTime(userId: userId),
        )
    }

    func getLastActiveBootEpoch(userId: String) async throws -> TimeInterval? {
        do {
            let stored = try await keychainServiceFacade.getValue(
                for: BitwardenKeychainItem.lastActiveBootEpoch(userId: userId),
            )
            return TimeInterval(stored)
        } catch KeychainServiceError.osStatusError(errSecItemNotFound), KeychainServiceError.keyNotFound {
            return nil
        }
    }

    func setLastActiveBootEpoch(_ bootEpoch: TimeInterval?, userId: String) async throws {
        let value = bootEpoch.map { String($0) }
        guard let value else {
            try await keychainServiceFacade.deleteValue(
                for: BitwardenKeychainItem.lastActiveBootEpoch(userId: userId),
            )
            return
        }

        try await keychainServiceFacade.setValue(
            value,
            for: BitwardenKeychainItem.lastActiveBootEpoch(userId: userId),
        )
    }

    // MARK: Unsuccessful Unlock Attempts

    func getUnsuccessfulUnlockAttempts(userId: String) async throws -> Int? {
        let stored = try await keychainServiceFacade.getValue(
            for: BitwardenKeychainItem.unsuccessfulUnlockAttempts(userId: userId),
        )
        return Int(stored)
    }

    func setUnsuccessfulUnlockAttempts(_ attempts: Int, userId: String) async throws {
        let value = String(attempts)
        try await keychainServiceFacade.setValue(
            value,
            for: BitwardenKeychainItem.unsuccessfulUnlockAttempts(userId: userId),
        )
    }

    // MARK: Vault Timeout

    func getVaultTimeout(userId: String) async throws -> Int? {
        let stored = try await keychainServiceFacade.getValue(
            for: BitwardenKeychainItem.vaultTimeout(userId: userId),
        )
        return Int(stored)
    }

    func setVaultTimeout(minutes: Int, userId: String) async throws {
        let value = String(minutes)
        try await keychainServiceFacade.setValue(value, for: BitwardenKeychainItem.vaultTimeout(userId: userId))
    }
}
