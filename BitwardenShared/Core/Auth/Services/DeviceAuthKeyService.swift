import BitwardenSdk
import CryptoKit
import Foundation
import os.log

// MARK: - DeviceAuthKeyService

/// Service to manage the device auth key.
protocol DeviceAuthKeyService { // sourcery: AutoMockable
    /// Signs a passkey assertion request with the device auth key, if it exists and matches the given
    /// ``recordIdentifier``.
    ///
    /// - Parameters:
    ///   - request: The passkey assertion request.
    ///   - recordIdentifier: The record identifier for the ``ASPasskeyCredentialIdentity`` related to the passkey
    ///     assertion request, which should be equal to the cipher ID of the device auth key record.
    ///   - userId: Currently active user ID for the account.
    /// - Returns: A ``GetAssertionResult``, or `nil` if the device auth key does not exist.
    func assertDeviceAuthKey(
        for request: GetAssertionRequest,
        recordIdentifier: String,
        userId: String,
    ) async throws -> GetAssertionResult?

    /// Create device auth key with PRF encryption key.
    ///
    /// Before calling, the vault must be unlocked to wrap user encryption key.
    ///
    /// - Parameters:
    ///   - masterPasswordHash: Master password hash suitable for server authentication.
    ///   - overwrite: Whether to overwrite an existing value if a previous one is already found.
    ///   - userId: Currently active user ID for the account.
    func createDeviceAuthKey(
        masterPasswordHash: String,
        overwrite: Bool,
        userId: String,
    ) async throws -> DeviceAuthKeyRecord

    /// Deletes the device auth key.
    ///
    /// - Parameters:
    ///   - userId: The user ID to delete the device auth key of.
    ///
    func deleteDeviceAuthKey(
        userId: String,
    ) async throws

    /// Retrieve the metadata for the device auth key, if it exists.
    ///
    /// - Parameters:
    ///   - userId: Currently active user ID for the account.
    func getDeviceAuthKeyMetadata(userId: String) async throws -> DeviceAuthKeyMetadata?
}

// MARK: - DefaultDeviceAuthKeyService

/// Implementation of DeviceAuthKeyService
struct DefaultDeviceAuthKeyService: DeviceAuthKeyService {
    // MARK: Properties

    private let deviceAuthKeychainRepository: DeviceAuthKeychainRepository

    // MARK: Initializers

    init(
        deviceAuthKeychainRepository: DeviceAuthKeychainRepository,
    ) {
        self.deviceAuthKeychainRepository = deviceAuthKeychainRepository
    }

    // MARK: Functions

    func assertDeviceAuthKey(
        for request: GetAssertionRequest,
        recordIdentifier: String,
        userId: String,
    ) async throws -> GetAssertionResult? {
        throw DeviceAuthKeyError.notImplemented
    }

    func createDeviceAuthKey(
        masterPasswordHash: String,
        overwrite: Bool,
        userId: String,
    ) async throws -> DeviceAuthKeyRecord {
        throw DeviceAuthKeyError.notImplemented
    }

    func deleteDeviceAuthKey(
        userId: String,
    ) async throws {
        try await deviceAuthKeychainRepository.deleteDeviceAuthKey(userId: userId)
    }

    func getDeviceAuthKeyMetadata(userId: String) async throws -> DeviceAuthKeyMetadata? {
        try await deviceAuthKeychainRepository.getDeviceAuthKeyMetadata(userId: userId)
    }

    // MARK: Private

    /// Retrieve the device auth key secrets, if the record exists. This is private because no other class should need
    /// to have access to the private key; all of the auth is done here.
    ///
    /// Before calling, the vault must be unlocked to wrap user encryption key.
    ///
    /// - Parameters:
    ///   - userId: User ID for the account to fetch.
    private func getDeviceAuthKeyRecord(userId: String) async throws -> DeviceAuthKeyRecord? {
        try await deviceAuthKeychainRepository.getDeviceAuthKey(userId: userId)
    }
}

// MARK: - DeviceAuthKeyError

enum DeviceAuthKeyError: Error {
    case missingOrInvalidKey
    case notImplemented
}
