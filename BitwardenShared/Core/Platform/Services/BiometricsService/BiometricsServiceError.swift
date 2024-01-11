// MARK: - BiometricsServiceError

/// An error thrown by a BiometricsService.
///
enum BiometricsServiceError: Error, Equatable {
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
