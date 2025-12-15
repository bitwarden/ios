// MARK: - BiometricsStateService

/// A protocol for a service that provides state management functionality around biometrics.
///
public protocol BiometricsStateService: ActiveAccountStateProvider {
    /// Get the active user's Biometric Authentication Preference.
    ///
    /// - Returns: A `Bool` indicating the user's preference for using biometric authentication.
    ///     If `true`, the device should attempt biometric authentication for authorization events.
    ///     If `false`, the device should not attempt biometric authentication for authorization events.
    ///
    func getBiometricAuthenticationEnabled() async throws -> Bool

    /// Sets the user's Biometric Authentication Preference.
    ///
    /// - Parameter isEnabled: A `Bool` indicating the user's preference for using biometric authentication.
    ///     If `true`, the device should attempt biometric authentication for authorization events.
    ///     If `false`, the device should not attempt biometric authentication for authorization events.
    ///
    func setBiometricAuthenticationEnabled(_ isEnabled: Bool?) async throws
}

public protocol BiometricsKeychainRepository {
    func deleteUserBiometricAuthKey(userId: String) async throws

    func getUserBiometricAuthKey(userId: String) async throws -> String

    func setUserBiometricAuthKey(userId: String, value: String) async throws
}
