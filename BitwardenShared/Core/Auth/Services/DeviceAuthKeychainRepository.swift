import Foundation

// MARK: - DeviceAuthKeychainRepository

/// A service that provides access to keychain values related to device auth.
///
protocol DeviceAuthKeychainRepository { // sourcery: AutoMockable
    // MARK: Device Auth Key

    /// Attempts to delete the device auth key and its metadata from the keychain.
    ///
    /// - Parameter userId: The user ID associated with the stored device auth key.
    ///
    func deleteDeviceAuthKey(userId: String) async throws

    /// Gets the stored device auth key for a user from the keychain.
    ///
    /// - Parameter userId: The user ID associated with the stored device auth key.
    /// - Returns: The device auth key.
    ///
    func getDeviceAuthKey(userId: String) async throws -> DeviceAuthKeyRecord?

    /// Gets the metadata about the stored device auth key for a user from the keychain.
    ///
    /// - Parameter userId: The user ID associated with the stored device auth key.
    /// - Returns: The device auth key metadata.
    ///
    func getDeviceAuthKeyMetadata(userId: String) async throws -> DeviceAuthKeyMetadata?

    /// Stores the device auth key metadata for a user in the keychain.
    ///
    /// - Parameters:
    ///   - metadata: The metadata of device auth key to store.
    ///   - userId: The user's ID, used to get back the device auth key later on.
    ///
    func setDeviceAuthKeyMetadata(
        metadata: DeviceAuthKeyMetadata,
        userId: String,
    ) async throws

    /// Stores the device auth key for a user in the keychain.
    ///
    /// - Parameters:
    ///   - record: The device auth key, including the secrets, to store.
    ///   - userId: The user's ID, used to get back the device auth key later on.
    ///
    func setDeviceAuthKeyRecord(
        record: DeviceAuthKeyRecord,
        userId: String,
    ) async throws
}
