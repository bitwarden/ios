import LocalAuthentication
import OSLog

// MARK: - BiometricsService

/// A protocol for returning the available authentication policies and access controls for the user's device.
///
protocol BiometricsService: AnyObject {
    /// Attempts to delete the userAuthKey from the keychain.
    ///
    /// - Parameter userId: The userId for the key to be deleted.
    ///
    func deleteUserAuthKey(for userId: String) async throws

    /// Returns the status for user BiometricAuthentication.
    ///
    /// - Returns: The a `BiometricAuthorizationStatus`.
    ///
    func getBiometricAuthStatus() -> BiometricAuthorizationStatus

    /// Attempts to retrieve a userAuthKey from the keychain with biometrics.
    ///
    /// - Parameter userId: The userId for the key to be retrieved.
    /// - Returns: The user auth key.
    ///
    func retrieveUserAuthKey(for userId: String) async throws -> String?

    /// Attempts to save an auth key to the keychain with biometrics.
    ///
    /// - Parameters
    ///   - value: The key to be stored.
    ///   - userId: The userId for the key to be saved to the keychain.
    ///
    func setUserAuthKey(value: String, for userId: String) async throws
}

// MARK: - DefaultBiometricsService

/// A default implementation of `BiometricsService`, which returns the available authentication policies
/// and access controls for the user's device, and logs an error if one occurs
/// while obtaining the device's biometric authentication type.
///
class DefaultBiometricsService: BiometricsService {
    func getBiometricAuthStatus() -> BiometricAuthorizationStatus {
        let context = LAContext()
        var error: NSError?

        let biometricAuthType = getBiometricAuthenticationType()

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

    func deleteUserAuthKey(for userId: String) async throws {
        guard let bundleId = Bundle.main.bundleIdentifier else {
            throw BiometricsServiceError.deleteAuthKeyFailed
        }

        let key = biometricStorageKey(for: userId)
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

    func retrieveUserAuthKey(for userId: String) async throws -> String? {
        let key = biometricStorageKey(for: userId)
        guard let bundleId = Bundle.main.bundleIdentifier,
              try await LAContext().evaluatePolicy(
                  .deviceOwnerAuthenticationWithBiometrics,
                  localizedReason: Localizations.useBiometricsToUnlock
              ) else {
            return nil
        }
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
            return nil
        }

        if let resultDictionary = item as? [String: Any],
           let data = resultDictionary[kSecValueData as String] as? Data {
            let string = String(decoding: data, as: UTF8.self)
            guard !string.isEmpty else {
                return nil
            }
            return string
        }

        return nil
    }

    func setUserAuthKey(value: String, for userId: String) async throws {
        guard let bundleId = Bundle.main.bundleIdentifier else {
            throw BiometricsServiceError.setAuthKeyFailed
        }
        let key = biometricStorageKey(for: userId)

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
            kSecValueData: value.data(using: .utf8)!,
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

    // MARK: Private Methods

    private func biometricStorageKey(for userId: String) -> String {
        "biometric_key_\(userId)"
    }

    private func getBiometricAuthenticationType() -> BiometricAuthenticationType? {
        let authContext = LAContext()
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
}
