import BitwardenSdk
import LocalAuthentication
import OSLog

// MARK: - BiometricsStatus

enum BiometricsUnlockStatus: Equatable {
    /// Biometric Unlock is available.
    case available(BiometricAuthenticationType, enabled: Bool, hasValidIntegrity: Bool)

    /// Biometric Unlock is not available.
    case notAvailable
}

// MARK: - BiometricsService

/// A protocol for returning the available authentication policies and access controls for the user's device.
///
protocol BiometricsService: AnyObject {
    /// Configures the device Biometric Integrity state.
    ///     Should be called following a successful launch when biometric unlock is enabled.
    func configureBiometricIntegrity() async throws

    /// Returns the status for user BiometricAuthentication.
    ///
    /// - Returns: The a `BiometricAuthorizationStatus`.
    ///
    func getBiometricUnlockStatus() async throws -> BiometricsUnlockStatus

    /// Sets the biometric unlock preference for a given user.
    ///
    /// - Parameters:
    ///     - authKey: An optional `String` representing the user auth key. If nil, Biometric Unlock is disabled.
    ///     - userId: The id of the user. Defaults to the active user id.
    ///
    func setBiometricUnlockKey(authKey: String?, for userId: String?) async throws

    /// Attempts to retrieve a user's auth key with biometrics.
    ///
    /// - Parameter userId: The userId for the stored auth key.
    ///
    func getUserAuthKey(for userId: String?) async throws -> String
}

// MARK: - DefaultBiometricsService

/// A default implementation of `BiometricsService`, which returns the available authentication policies
/// and access controls for the user's device, and logs an error if one occurs
/// while obtaining the device's biometric authentication type.
///
class DefaultBiometricsService: BiometricsService {
    // MARK: Parameters

    /// A service used to store the Biometric Integrity Source key/value pair.
    var stateService: StateService

    // MARK: Initialization

    /// Initializes the service.
    ///
    /// - Parameter stateService: The service used to update user preferences.
    ///
    init(stateService: StateService) {
        self.stateService = stateService
    }

    func configureBiometricIntegrity() async throws {
        if let state = getBiometricInegrityState() {
            let base64State = state.base64EncodedString()
            try await stateService.setBiometricIntegrityState(base64State)
        }
    }

    func getBiometricUnlockStatus() async throws -> BiometricsUnlockStatus {
        let biometryStatus = getBiometricAuthStatus()
        if case .lockedOut = biometryStatus {
            throw BiometricsServiceError.deleteAuthKeyFailed
        }
        let hasEnabledBiometricUnlock = try await stateService.getBiometricAuthenticationEnabled()
        let hasValidIntegrityState = await isBiometricIntegrityValid()
        switch biometryStatus {
        case let .authorized(type):
            return .available(
                type,
                enabled: hasEnabledBiometricUnlock,
                hasValidIntegrity: hasValidIntegrityState
            )
        case .denied,
             .lockedOut,
             .noBiometrics,
             .notDetermined,
             .notEnrolled,
             .unknownError:
            return .notAvailable
        }
    }

    func setBiometricUnlockKey(authKey: String?, for userId: String? = nil) async throws {
        guard let authKey else {
            try await stateService.setBiometricAuthenticationEnabled(false)
            try? await deleteUserAuthKey(for: userId)
            return
        }

        try await setUserAuthKey(value: authKey, for: userId)
        try await stateService.setBiometricAuthenticationEnabled(true)
    }

    func getUserAuthKey(for userId: String? = nil) async throws -> String {
        let context = LAContext()
        guard let bundleId = Bundle.main.bundleIdentifier,
              try await context.evaluatePolicy(
                  .deviceOwnerAuthenticationWithBiometrics,
                  localizedReason: Localizations.useBiometricsToUnlock
              ) else {
            throw BiometricsServiceError.getAuthKeyFailed
        }
        let id = try await getUserId(userId)
        let key = biometricStorageKey(for: id)

        let searchQuery = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: bundleId,
            kSecAttrAccount: key,
            kSecMatchLimit: kSecMatchLimitOne,
            kSecReturnData: true,
            kSecReturnAttributes: true,
        ] as CFDictionary

        var item: AnyObject?
        let status = SecItemCopyMatching(searchQuery, &item)

        if status == errSecItemNotFound {
            throw BiometricsServiceError.getAuthKeyFailed
        }

        if let resultDictionary = item as? [String: Any],
           let data = resultDictionary[kSecValueData as String] as? Data {
            let string = String(decoding: data, as: UTF8.self)
            guard !string.isEmpty else {
                throw BiometricsServiceError.getAuthKeyFailed
            }
            if let state = context.evaluatedPolicyDomainState {
                let base64State = state.base64EncodedString()
                try await stateService.setBiometricIntegrityState(base64State)
            }
            return string
        }

        throw BiometricsServiceError.getAuthKeyFailed
    }

    /// Attempts to save an auth key to the keychain with biometrics.
    ///
    /// - Parameters
    ///   - value: The key to be stored.
    ///   - userId: The userId for the key to be saved to the keychain.
    ///
    private func setUserAuthKey(value: String, for userId: String?) async throws {
        guard let bundleId = Bundle.main.bundleIdentifier else {
            throw BiometricsServiceError.setAuthKeyFailed
        }
        let id = try await getUserId(userId)
        let key = biometricStorageKey(for: id)

        var error: Unmanaged<CFError>?
        let accessControl = SecAccessControlCreateWithFlags(
            nil,
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            .biometryCurrentSet,
            &error
        )

        guard accessControl != nil,
              error == nil else { throw BiometricsServiceError.setAuthKeyFailed }

        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: bundleId,
            kSecAttrAccount: key,
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

// MARK: Private Methods

extension DefaultBiometricsService {
    private func biometricStorageKey(for userId: String) -> String {
        "biometric_key_\(userId)"
    }

    /// Attempts to delete the userAuthKey from the keychain.
    ///
    /// - Parameter userId: The userId for the key to be deleted.
    ///
    private func deleteUserAuthKey(for userId: String?) async throws {
        guard let bundleId = Bundle.main.bundleIdentifier else {
            throw BiometricsServiceError.deleteAuthKeyFailed
        }
        let id = try await getUserId(userId)

        let key = biometricStorageKey(for: id)
        let queryDictionary = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: bundleId,
            kSecAttrAccount: key,
        ] as CFDictionary

        let deleteStatus = SecItemDelete(queryDictionary)

        if deleteStatus != errSecSuccess {
            throw BiometricsServiceError.deleteAuthKeyFailed
        }
    }

    /// Returns the status for device BiometricAuthenticationType.
    ///
    /// - Returns: The `BiometricAuthenticationType`.
    ///
    private func getBiometricAuthenticationType(_ suppliedContext: LAContext? = nil) -> BiometricAuthenticationType? {
        let authContext = suppliedContext ?? LAContext()
        var error: NSError?

        guard authContext.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            Logger.processor.error("Error checking biometrics type: \(error)")
            return nil
        }

        switch authContext.biometryType {
        case .none,
             .opticID:
            return .none
        case .touchID:
            return .touchID
        case .faceID:
            return .faceID
        @unknown default:
            return .none
        }
    }

    /// Returns the status for user BiometricAuthentication.
    ///
    /// - Parameter suppliedContext: The LAContext in which to check for the status.
    /// - Returns: The a `BiometricAuthorizationStatus`.
    ///
    private func getBiometricAuthStatus(_ suppliedContext: LAContext? = nil) -> BiometricAuthorizationStatus {
        let context = suppliedContext ?? LAContext()
        var error: NSError?

        let biometricAuthType = getBiometricAuthenticationType(context)

        // Check if the device supports biometric authentication.
        if let biometricAuthType,
           context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            // Biometrics are available and enrolled, permissions are undetermined or granted.
            return .authorized(biometricAuthType)
        } else {
            guard let biometricAuthType else {
                // Biometrics are not available on the device.
                Logger.application.log("Biometry is not available.")
                return .noBiometrics
            }
            guard let laError = error as? LAError else {
                // A non LAError occured
                Logger.application.log("Other error: \(error?.localizedDescription ?? "")")
                return .unknownError(error?.localizedDescription ?? "", biometricAuthType)
            }

            // If canEvaluatePolicy returns false, check the error code.
            switch laError.code {
            case .biometryNotAvailable:
                // The user has denied Biometrics permission for this app.
                Logger.application.log("Biometric permission denied!")
                return .denied(biometricAuthType)
            case .biometryNotEnrolled:
                // Biometrics are supported but not enrolled.
                Logger.application.log("Biometry is supported but not enrolled.")
                return .notEnrolled(biometricAuthType)
            case .biometryLockout:
                // Biometrics are locked out, typically due to too many failed attempts.
                Logger.application.log("Biometry is temporarily locked out.")
                return .lockedOut(biometricAuthType)
            default:
                // Other types of errors.
                Logger.application.log("Other error: \(laError.localizedDescription)")
                return .unknownError(laError.localizedDescription, biometricAuthType)
            }
        }
    }

    /// Returns the `Data` for device evaluatedPolicyDomainState.
    ///
    /// - Returns: The `Data` for evaluatedPolicyDomainState.
    ///
    private func getBiometricInegrityState() -> Data? {
        let context = LAContext()
        var error: NSError?
        context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        return context.evaluatedPolicyDomainState
    }

    private func getUserId(_ id: String?) async throws -> String {
        if let id {
            return id
        }
        return try await stateService.getActiveAccountId()
    }

    /// Checks if the device evaluatedPolicyDomainState matches the data saved to user defaults.
    ///
    /// - Returns: A `Bool` indicating if the stored Data matches the current data.
    ///     If no data is stored to the device, `true` is returned by default.
    ///
    private func isBiometricIntegrityValid() async -> Bool {
        guard let data = getBiometricInegrityState() else {
            // Fallback for devices unable to retrieve integrity state.
            return true
        }
        let integrityString: String? = try? await stateService.getBiometricIntegrityState()
        return data.base64EncodedString() == integrityString
    }
}
