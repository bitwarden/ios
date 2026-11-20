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
    func getDeviceAuthKey(userId: String) async throws -> DeviceAuthKeyKeychainRecord?

    /// Gets the metadata about the stored device auth key for a user from the keychain.
    ///
    /// - Parameter userId: The user ID associated with the stored device auth key.
    /// - Returns: The device auth key metadata.
    ///
    func getDeviceAuthKeyMetadata(userId: String) async throws -> DeviceAuthKeyKeychainMetadata?

    /// Stores the device auth key and metadata for a user in the keychain.
    ///
    /// - Parameters:
    ///   - record: The device auth key, including the secrets, to store.
    ///   - metadata: The metadata of device auth key to store.
    ///   - userId: The user's ID, used to get back the device auth key later on.
    ///
    func setDeviceAuthKey(
        record: DeviceAuthKeyKeychainRecord,
        metadata: DeviceAuthKeyKeychainMetadata,
        userId: String,
    ) async throws

    /// Gets the ID of the user that has a device auth key on this device for an email address.
    /// This value stays in the keychain after the user logs out.
    ///
    /// - Parameter email: The user's email address.
    /// - Returns: The user ID, or `nil` if there's no device auth key for the email.
    ///
    func getDeviceAuthKeyUserId(email: String) async throws -> String?

    /// Stores the device auth key metadata for a user in the keychain.
    ///
    /// - Parameters:
    ///   - metadata: The metadata of device auth key to store.
    ///   - userId: The user's ID, used to get back the device auth key later on.
    ///
    func setDeviceAuthKeyMetadata(_ metadata: DeviceAuthKeyKeychainMetadata, userId: String) async throws

    /// Stores the device auth key secrets for a user in the keychain.
    ///
    /// - Parameters:
    ///   - record: The device auth key, including the secrets, to store.
    ///   - userId: The user's ID, used to get back the device auth key later on.
    ///
    func setDeviceAuthKeyRecord(_ record: DeviceAuthKeyKeychainRecord, userId: String) async throws

    /// Stores the ID of the user that has a device auth key on this device for an email address.
    ///
    /// - Parameters:
    ///   - userId: The user's ID, or `nil` to remove the entry.
    ///   - email: The user's email address.
    ///
    func setDeviceAuthKeyUserId(_ userId: String?, email: String) async throws
}
