// MARK: - BiometricsStateService

/// A protocol for a service that provides state management functionality around biometrics.
///
public protocol BiometricsStateService: ActiveAccountStateProvider {
    /// Get a user's Biometric Authentication Preference.
    ///
    /// - Parameter userId: The user ID for the user to get the biometric authentication preference.
    ///     Defaults to the active user if nil.
    /// - Returns: A `Bool` indicating the user's preference for using biometric authentication.
    ///     If `true`, the device should attempt biometric authentication for authorization events.
    ///     If `false`, the device should not attempt biometric authentication for authorization events.
    ///
    func getBiometricAuthenticationEnabled(userId: String?) async throws -> Bool

    /// Sets a user's Biometric Authentication Preference.
    ///
    /// - Parameters:
    ///   - isEnabled: A `Bool` indicating the user's preference for using biometric authentication.
    ///     If `true`, the device should attempt biometric authentication for authorization events.
    ///     If `false`, the device should not attempt biometric authentication for authorization events.
    ///   - userId: The user ID for the user to set the biometric authentication preference.
    ///     Defaults to the active user if nil.
    ///
    func setBiometricAuthenticationEnabled(_ isEnabled: Bool?, userId: String?) async throws
}
