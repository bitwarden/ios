// MARK: - BiometricAuthenticationType

/// The enumeration biometric authentication types.
///
enum BiometricAuthenticationType: Equatable {
    /// FaceID biometric authentication.
    case faceID

    /// TouchID biometric authentication.
    case touchID

    /// OpticID biometric authentication.
    case opticID

    /// Unknown other biometric authentication
    case unknown
}
