import BitwardenKit
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
protocol BiometricsRepository: AnyObject { // sourcery: AutoMockable
    /// Returns the device BiometricAuthenticationType.
    ///
    /// - Returns: The `BiometricAuthenticationType`.
    ///
    func getBiometricAuthenticationType() -> BiometricAuthenticationType?

    /// Returns the status for user BiometricAuthentication.
    ///
    /// - Parameter userId: The user ID for the user to get biometric unlock status. Defaults to the active user if nil.
    /// - Returns: The a `BiometricAuthorizationStatus`.
    ///
    func getBiometricUnlockStatus(userId: String?) async throws -> BiometricsUnlockStatus

    /// Attempts to retrieve a user's auth key with biometrics.
    ///
    func getUserAuthKey() async throws -> String

    /// Sets the biometric unlock preference for a user.
    ///
    /// If permissions have not been requested, this request should trigger the system permissions dialog.
    ///
    /// - Parameters:
    ///   - authKey: An optional `String` representing the user auth key. If nil, Biometric Unlock is disabled.
    ///   - userId: The user ID for the user to set biometric unlock. Defaults to the active user if nil.
    ///
    func setBiometricUnlockKey(authKey: String?, userId: String?) async throws
}

extension BiometricsRepository {
    /// Returns the status for the active user's BiometricAuthentication.
    ///
    /// - Returns: The a `BiometricAuthorizationStatus`.
    ///
    func getBiometricUnlockStatus() async throws -> BiometricsUnlockStatus {
        try await getBiometricUnlockStatus(userId: nil)
    }

    /// Sets the biometric unlock preference for the active user.
    ///
    /// If permissions have not been requested, this request should trigger the system permissions dialog.
    ///
    /// - Parameter authKey: An optional `String` representing the user auth key. If nil, Biometric Unlock is disabled.
    ///
    func setBiometricUnlockKey(authKey: String?) async throws {
        try await setBiometricUnlockKey(authKey: authKey, userId: nil)
    }
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
    var keychainRepository: BiometricsKeychainRepository

    /// A service used to update user preferences.
    var stateService: BiometricsStateService

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
        keychainService: BiometricsKeychainRepository,
        stateService: BiometricsStateService,
    ) {
        self.biometricsService = biometricsService
        keychainRepository = keychainService
        self.stateService = stateService
    }

    func getBiometricAuthenticationType() -> BiometricAuthenticationType? {
        biometricsService.getBiometricAuthenticationType()
    }

    func setBiometricUnlockKey(authKey: String?, userId: String?) async throws {
        let userId = try await stateService.userIdOrActive(userId)
        guard let authKey,
              try await biometricsService.evaluateBiometricPolicy() else {
            try await stateService.setBiometricAuthenticationEnabled(false, userId: userId)
            try? await deleteUserAuthKey(userId: userId)
            return
        }

        try await setUserBiometricAuthKey(value: authKey, userId: userId)
        try await stateService.setBiometricAuthenticationEnabled(true, userId: userId)
    }

    func getBiometricUnlockStatus(userId: String?) async throws -> BiometricsUnlockStatus {
        let biometryStatus = biometricsService.getBiometricAuthStatus()
        if case .lockedOut = biometryStatus {
            throw BiometricsServiceError.biometryLocked
        }
        let hasEnabledBiometricUnlock = try await stateService.getBiometricAuthenticationEnabled(userId: userId)
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

        do {
            let string = try await keychainRepository.getUserBiometricAuthKey(userId: id)
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
                case errSecItemNotFound:
                    throw BiometricsServiceError.getAuthKeyFailed
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
    /// Attempts to delete a user's AuthKey from the keychain.
    ///
    /// - Parameter userId: The user ID for the user to delete the auth key.
    ///
    private func deleteUserAuthKey(userId: String) async throws {
        do {
            try await keychainRepository.deleteUserBiometricAuthKey(userId: userId)
        } catch {
            throw BiometricsServiceError.deleteAuthKeyFailed
        }
    }

    /// Attempts to save an auth key to the keychain with biometrics.
    ///
    /// - Parameters:
    ///   - value: The key to be stored.
    ///   - userId: The user ID for the user to set the auth key.
    ///
    private func setUserBiometricAuthKey(value: String, userId: String) async throws {
        do {
            try await keychainRepository.setUserBiometricAuthKey(userId: userId, value: value)
        } catch {
            throw BiometricsServiceError.setAuthKeyFailed
        }
    }
}
