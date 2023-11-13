// MARK: - AccountSecurityEffect

/// The enumeration of effects handled by the `AccountSecurityProcessor`.
///
enum AccountSecurityEffect {
    /// Gets the available authentication policies and access controls for the user's device.
    case getBiometricAuthenticationType
}
