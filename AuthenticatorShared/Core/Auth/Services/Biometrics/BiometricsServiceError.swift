// MARK: - BiometricsServiceError

/// An error thrown by a BiometricsRepository.
///
enum BiometricsServiceError: Error, Equatable {
    /// An error when the user, app, or system cancels a biometric unlock
    ///
    case biometryCancelled

    /// An error for when biometry fails for a benign reason.
    ///
    case biometryFailed

    /// An error for when the user has passed the maximum failed attempts at biometric unlock.
    ///
    case biometryLocked

    /// An error for when deleting an auth key from the keychain fails.
    ///
    case deleteAuthKeyFailed

    /// An error for when retrieving an auth key from the keychain fails.
    ///
    case getAuthKeyFailed

    /// An error for when saving an auth key to the keychain fails.
    ///
    case setAuthKeyFailed
}
