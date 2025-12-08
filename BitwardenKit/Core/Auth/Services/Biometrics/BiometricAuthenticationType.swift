// MARK: - BiometricAuthenticationType

/// The enumeration biometric authentication types.
///
public enum BiometricAuthenticationType: Equatable {
    /// FaceID biometric authentication.
    case faceID

    /// OpticID biometric authentication.
    case opticID

    /// TouchID biometric authentication.
    case touchID

    /// Unknown other biometric authentication
    case unknown
}
