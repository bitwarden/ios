// MARK: - BiometricAuthorizationType

/// The enumeration biometric authentication authorization.
///
enum BiometricAuthorizationStatus: Equatable {
    /// BiometricAuth access has been authorized or may be authorized pending a system permissions alert.
    case authorized(BiometricAuthenticationType)

    /// BiometricAuth access has been denied.
    case denied(BiometricAuthenticationType)

    /// BiometricAuth access denied due to repeated failed attempts.
    case lockedOut(BiometricAuthenticationType)

    /// No biometric authentication available on the user's device.
    case noBiometrics

    /// BiometricAuth access has not been determined yet.
    case notDetermined

    /// The user has not enrolled in BiometricAuth on this device.
    case notEnrolled(BiometricAuthenticationType)

    /// An unknown error case
    case unknownError(String, BiometricAuthenticationType)

    var shouldDisplayiometricsToggle: Bool {
        switch self {
        case .authorized,
             .lockedOut:
            return true
        case .denied,
             .noBiometrics,
             .notDetermined,
             .notEnrolled,
             .unknownError:
            return false
        }
    }
}
