import BitwardenSdk
import LocalAuthentication

// MARK: - BiometricsStatus

enum BiometricsUnlockStatus: Equatable {
    /// Biometric Unlock is available.
    case available(BiometricAuthenticationType, enabled: Bool)

    /// Biometric Unlock is not available.
    case notAvailable

    // MARK: Computed Properties

    /// Whether biometric unlock is both available and enabled.
    var isEnabled: Bool {
        guard case let .available(_, enabled) = self else {
            return false
        }
        return enabled
    }
}

// MARK: - BiometricsRepository

/// A protocol for returning the available authentication policies and access controls for the user's device.
///
protocol BiometricsRepository: AnyObject {
    /// Returns the device BiometricAuthenticationType.
    ///
    /// - Returns: The `BiometricAuthenticationType`.
    ///
    func getBiometricAuthenticationType() -> BiometricAuthenticationType?

    /// Returns the status for user BiometricAuthentication.
    ///
    /// - Returns: The a `BiometricAuthorizationStatus`.
    ///
    func getBiometricUnlockStatus() async throws -> BiometricsUnlockStatus

    /// Attempts to retrieve a user's auth key with biometrics.
    ///
    func getUserAuthKey() async throws -> String

    /// Sets the biometric unlock preference for the active user.
    ///   If permissions have not been requested, this request should trigger the system permisisons dialog.
    ///
    /// - Parameter authKey: An optional `String` representing the user auth key. If nil, Biometric Unlock is disabled.
    ///
    func setBiometricUnlockKey(authKey: String?) async throws
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

    /// A service used to update user preferences.
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

    func getBiometricAuthenticationType() -> BiometricAuthenticationType? {
        biometricsService.getBiometricAuthenticationType()
    }

    func setBiometricUnlockKey(authKey: String?) async throws {
        guard let authKey,
              try await biometricsService.evaluateBiometricPolicy() else {
            try await stateService.setBiometricAuthenticationEnabled(false)
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
        switch biometryStatus {
        case let .authorized(type):
            return .available(type, enabled: hasEnabledBiometricUnlock)
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
                case errSecAuthFailed,
                     errSecUserCanceled,
                     kLAErrorAppCancel,
                     kLAErrorSystemCancel,
                     kLAErrorUserCancel:
                    throw BiometricsServiceError.biometryCancelled
                case kLAErrorBiometryDisconnected,
                     kLAErrorUserFallback:
                    throw BiometricsServiceError.biometryFailed
                default:
                    throw error
                }
            }
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
