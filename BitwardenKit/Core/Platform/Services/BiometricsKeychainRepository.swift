// MARK: - BiometricsKeychainRepository

/// A service that provides access to biometric-protected user auth keys in the keychain.
///
public protocol BiometricsKeychainRepository { // sourcery: AutoMockable
    /// Deletes the biometric-protected user auth key for the specified user from the keychain.
    ///
    /// - Parameters:
    ///   - userId: The user ID whose user auth key should be deleted.
    ///
    func deleteUserBiometricAuthKey(userId: String) async throws

    /// Retrieves the biometric-protected user auth key for the specified user from the keychain.
    ///
    /// This operation may prompt the user for biometric authentication before returning the key.
    ///
    /// - Parameters:
    ///   - userId: The user ID whose user auth key should be retrieved.
    ///
    /// - Returns: The user auth key associated with the specified user.
    ///
    func getUserBiometricAuthKey(userId: String) async throws -> String

    /// Stores or updates the biometric-protected user auth key for the specified user in the keychain.
    ///
    /// The stored key will be protected by biometric authentication and will require user authentication
    /// to retrieve in the future.
    ///
    /// - Parameters:
    ///   - userId: The user ID whose user auth key should be stored.
    ///   - value: The user auth key to store.
    ///
    /// - Throws: An error if the storage operation fails or if biometric authentication is required but fails.
    ///
    func setUserBiometricAuthKey(userId: String, value: String) async throws
}
