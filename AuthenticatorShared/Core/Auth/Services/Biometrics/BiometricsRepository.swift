import BitwardenSdk
import LocalAuthentication

// MARK: - BiometricsStatus

enum BiometricsUnlockStatus: Equatable {
    /// Biometric Unlock is available.
    case available(BiometricAuthenticationType, enabled: Bool, hasValidIntegrity: Bool)

    /// Biometric Unlock is not available.
    case notAvailable

    // MARK: Computed Properties

    /// Whether biometric unlock is both available and enabled.
    var isEnabled: Bool {
        guard case let .available(_, enabled, _) = self else {
            return false
        }
        return enabled
    }
}

// MARK: - BiometricsRepository

/// A protocol for returning the available authentication policies and access controls for the user's device.
///
protocol BiometricsRepository: AnyObject {
    /// Configures the device Biometric Integrity state.
    ///     Should be called following a successful launch when biometric unlock is enabled.
    func configureBiometricIntegrity() async throws

    /// Sets the biometric unlock preference for the active user.
    ///   If permissions have not been requested, this request should trigger the system permisisons dialog.
    ///
    /// - Parameter authKey: An optional `String` representing the user auth key. If nil, Biometric Unlock is disabled.
    ///
    func setBiometricUnlockKey(authKey: String?) async throws

    /// Returns the status for user BiometricAuthentication.
    ///
    /// - Returns: The a `BiometricAuthorizationStatus`.
    ///
    func getBiometricUnlockStatus() async throws -> BiometricsUnlockStatus

    /// Attempts to retrieve a user's auth key with biometrics.
    ///
    func getUserAuthKey() async throws -> String
}

// MARK: - DefaultBiometricsRepository

/// A default implementation of `BiometricsRepository`, which returns the available authentication policies
/// and access controls for the user's device, and logs an error if one occurs
/// while obtaining the device's biometric authentication type.
///
class DefaultBiometricsRepository: BiometricsRepository {
    // MARK: Parameters

    /// A service used to track device biometry data & status.
    var biometricsService: BiometricsService

    /// A service used to store the UserAuthKey key/value pair.
    var keychainRepository: KeychainRepository

    /// A service used to store the Biometric Integrity Source key/value pair.
    var stateService: StateService

    // MARK: Initialization

    /// Initializes the service.
    ///
    /// - Parameters:
    ///   - biometricsService: The service used to track device biometry data & status.
    ///   - keychainService: The service used to store the UserAuthKey key/value pair.
    ///   - stateService: The service used to update user preferences.
    ///
    init(
        biometricsService: BiometricsService,
        keychainService: KeychainRepository,
        stateService: StateService
    ) {
        self.biometricsService = biometricsService
        keychainRepository = keychainService
        self.stateService = stateService
    }

    func configureBiometricIntegrity() async throws {
        if let state = biometricsService.getBiometricIntegrityState() {
            let base64State = state.base64EncodedString()
            try await stateService.setBiometricIntegrityState(base64State)
        }
    }

    func setBiometricUnlockKey(authKey: String?) async throws {
        guard let authKey,
              try await biometricsService.evaluateBiometricPolicy() else {
            try await stateService.setBiometricAuthenticationEnabled(false)
            try await stateService.setBiometricIntegrityState(nil)
            try? await deleteUserAuthKey()
            return
        }

        try await setUserBiometricAuthKey(value: authKey)
        try await stateService.setBiometricAuthenticationEnabled(true)
    }

    func getBiometricUnlockStatus() async throws -> BiometricsUnlockStatus {
        let biometryStatus = biometricsService.getBiometricAuthStatus()
        if case .lockedOut = biometryStatus {
            throw BiometricsServiceError.biometryLocked
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

    func getUserAuthKey() async throws -> String {
        let id = try await stateService.getActiveAccountId()
        let key = KeychainItem.biometrics(userId: id)

        do {
            let string = try await keychainRepository.getUserAuthKeyValue(for: key)
            guard !string.isEmpty else {
                throw BiometricsServiceError.getAuthKeyFailed
            }
            if let state = biometricsService.getBiometricIntegrityState() {
                let base64State = state.base64EncodedString()
                try await stateService.setBiometricIntegrityState(base64State)
            }
            return string
        } catch let error as KeychainServiceError {
            switch error {
            case .accessControlFailed,
                 .keyNotFound:
                throw BiometricsServiceError.getAuthKeyFailed
            case let .osStatusError(status):
                switch status {
                case kLAErrorBiometryLockout:
                    throw BiometricsServiceError.biometryLocked
                case errSecUserCanceled,
                     kLAErrorAppCancel,
                     kLAErrorSystemCancel,
                     kLAErrorUserCancel:
                    throw BiometricsServiceError.biometryCancelled
                case kLAErrorBiometryDisconnected,
                     kLAErrorUserFallback:
                    throw BiometricsServiceError.biometryFailed
                default:
                    throw BiometricsServiceError.getAuthKeyFailed
                }
            }
        } catch {
            throw BiometricsServiceError.getAuthKeyFailed
        }
    }
}

// MARK: Private Methods

extension DefaultBiometricsRepository {
    /// Attempts to delete the active user's AuthKey from the keychain.
    ///
    private func deleteUserAuthKey() async throws {
        let id = try await stateService.getActiveAccountId()
        let key = KeychainItem.biometrics(userId: id)
        do {
            try await keychainRepository.deleteUserAuthKey(for: key)
        } catch {
            throw BiometricsServiceError.deleteAuthKeyFailed
        }
    }

    /// Checks if the device evaluatedPolicyDomainState matches the data saved to user defaults.
    ///
    /// - Returns: A `Bool` indicating if the stored Data matches the current data.
    ///     If no data is stored to the device, `true` is returned by default.
    ///
    private func isBiometricIntegrityValid() async -> Bool {
        guard let data = biometricsService.getBiometricIntegrityState() else {
            // Fallback for devices unable to retrieve integrity state.
            return true
        }
        let integrityString: String? = try? await stateService.getBiometricIntegrityState()
        return data.base64EncodedString() == integrityString
    }

    /// Attempts to save an auth key to the keychain with biometrics.
    ///
    /// - Parameter value: The key to be stored.
    ///
    private func setUserBiometricAuthKey(value: String) async throws {
        let id = try await stateService.getActiveAccountId()
        let key = KeychainItem.biometrics(userId: id)

        do {
            try await keychainRepository.setUserAuthKey(for: key, value: value)
        } catch {
            throw BiometricsServiceError.setAuthKeyFailed
        }
    }
}
