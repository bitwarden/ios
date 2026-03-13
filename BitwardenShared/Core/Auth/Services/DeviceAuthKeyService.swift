import BitwardenKit
import BitwardenSdk
import Combine
import Foundation

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
    ///   - userId: The user ID for the account to assert the device auth key for.
    /// - Returns: A ``GetAssertionResult``, or `nil` if the device auth key does not exist.
    ///
    func assertDeviceAuthKey(
        for request: GetAssertionRequest,
        recordIdentifier: String,
        userId: String?,
    ) async throws -> GetAssertionResult?

    /// Create device auth key with PRF encryption key.
    ///
    /// Before calling, the vault must be unlocked to wrap user encryption key.
    ///
    /// - Parameters:
    ///   - masterPasswordHash: Master password hash suitable for server authentication.
    ///   - overwrite: Whether to overwrite an existing value if a previous one is already found.
    ///   - userId: The user ID for the account to create the device auth key for.
    ///
    func createDeviceAuthKey(
        masterPasswordHash: String,
        overwrite: Bool,
        userId: String?,
    ) async throws -> DeviceAuthKeyRecord

    /// Deletes the device auth key.
    ///
    /// - Parameters:
    ///   - userId: The user ID to delete the device auth key of.
    ///
    func deleteDeviceAuthKey(
        userId: String?,
    ) async throws

    /// Retrieve the metadata for the device auth key, if it exists.
    ///
    /// - Parameters:
    ///   - userId: The user ID for the account to get device auth key metadata for.
    ///
    func getDeviceAuthKeyMetadata(userId: String?) async throws -> DeviceAuthKeyMetadata?

    // MARK: Publishers

    /// A publisher for the device auth key
    func deviceAuthKeyPublisher() -> AnyPublisher<[String: Bool], Never>
}

// MARK: - Convenience Methods

extension DeviceAuthKeyService {
    /// Signs a passkey assertion request with the device auth key for the current user,
    /// if it exists and matches the given ``recordIdentifier``.
    ///
    /// - Parameters:
    ///   - request: The passkey assertion request.
    ///   - recordIdentifier: The record identifier for the ``ASPasskeyCredentialIdentity`` related to the passkey
    ///     assertion request, which should be equal to the cipher ID of the device auth key record.
    /// - Returns: A ``GetAssertionResult``, or `nil` if the device auth key does not exist.
    ///
    func assertDeviceAuthKey(
        for request: GetAssertionRequest,
        recordIdentifier: String,
    ) async throws -> GetAssertionResult? {
        try await assertDeviceAuthKey(
            for: request,
            recordIdentifier: recordIdentifier,
            userId: nil,
        )
    }

    /// Create device auth key with PRF encryption key for the current user.
    ///
    /// Before calling, the vault must be unlocked to wrap user encryption key.
    ///
    /// - Parameters:
    ///   - masterPasswordHash: Master password hash suitable for server authentication.
    ///   - overwrite: Whether to overwrite an existing value if a previous one is already found.
    ///
    func createDeviceAuthKey(
        masterPasswordHash: String,
        overwrite: Bool,
    ) async throws -> DeviceAuthKeyRecord {
        try await createDeviceAuthKey(
            masterPasswordHash: masterPasswordHash,
            overwrite: overwrite,
            userId: nil,
        )
    }

    /// Deletes the device auth key for the current user.
    ///
    func deleteDeviceAuthKey() async throws {
        try await deleteDeviceAuthKey(userId: nil)
    }

    /// Retrieve the metadata for the device auth key for the current user, if it exists.
    ///
    func getDeviceAuthKeyMetadata() async throws -> DeviceAuthKeyMetadata? {
        try await getDeviceAuthKeyMetadata(userId: nil)
    }
}

// MARK: - DefaultDeviceAuthKeyService

/// Default implementation of DeviceAuthKeyService
struct DefaultDeviceAuthKeyService: DeviceAuthKeyService {
    // MARK: Properties

    /// The provider for the active account state.
    private let activeAccountStateProvider: ActiveAccountStateProvider

    /// Repository for managing device auth keys in the keychain.
    private let deviceAuthKeychainRepository: DeviceAuthKeychainRepository

    /// A subject containing a userId and flag for the presence of the unlock passkey for logged in accounts.
    private let deviceAuthKeySubject = CurrentValueSubject<[String: Bool], Never>([:])

    // MARK: Initializers

    /// Creates a new instance of `DefaultDeviceAuthKeyService`.
    ///
    /// - Parameters:
    ///   - activeAccountStateProvider: The provider for the active account state.
    ///   - deviceAuthKeychainRepository: The repository for managing device auth keys in the keychain.
    ///
    init(
        activeAccountStateProvider: ActiveAccountStateProvider,
        deviceAuthKeychainRepository: DeviceAuthKeychainRepository,
    ) {
        self.activeAccountStateProvider = activeAccountStateProvider
        self.deviceAuthKeychainRepository = deviceAuthKeychainRepository
    }

    // MARK: Functions

    func assertDeviceAuthKey(
        for request: GetAssertionRequest,
        recordIdentifier: String,
        userId: String?,
    ) async throws -> GetAssertionResult? {
        // TODO: PM-26177 to finish building out this stub
        throw DeviceAuthKeyError.notImplemented
    }

    func createDeviceAuthKey(
        masterPasswordHash: String,
        overwrite: Bool,
        userId: String?,
    ) async throws -> DeviceAuthKeyRecord {
        let resolvedUserId = try await activeAccountStateProvider.userIdOrActive(userId)

        var curVal = deviceAuthKeySubject.value
        curVal[resolvedUserId] = true
        deviceAuthKeySubject.send(curVal)

        // TODO: PM-26177 to finish building out this stub
        throw DeviceAuthKeyError.notImplemented
    }

    func deleteDeviceAuthKey(
        userId: String?,
    ) async throws {
        let resolvedUserId = try await activeAccountStateProvider.userIdOrActive(userId)
        try await deviceAuthKeychainRepository.deleteDeviceAuthKey(userId: resolvedUserId)
    }

    func getDeviceAuthKeyMetadata(userId: String?) async throws -> DeviceAuthKeyMetadata? {
        let resolvedUserId = try await activeAccountStateProvider.userIdOrActive(userId)
        return try await deviceAuthKeychainRepository.getDeviceAuthKeyMetadata(userId: resolvedUserId)
    }

    // MARK: Private

    /// Retrieve the device auth key secrets, if the record exists. This is private because no other class should need
    /// to have access to the private key; all of the auth is done here.
    ///
    /// Before calling, the vault must be unlocked to wrap user encryption key.
    ///
    /// - Parameters:
    ///   - userId: User ID for the account to fetch. If `nil`, the active account will be used.
    ///
    private func getDeviceAuthKeyRecord(userId: String?) async throws -> DeviceAuthKeyRecord? {
        let resolvedUserId = try await activeAccountStateProvider.userIdOrActive(userId)
        return try await deviceAuthKeychainRepository.getDeviceAuthKey(userId: resolvedUserId)
    }

    // MARK: Publishers

    func deviceAuthKeyPublisher() -> AnyPublisher<[String: Bool], Never> {
        deviceAuthKeySubject.eraseToAnyPublisher()
    }
}

// MARK: - DeviceAuthKeyError

/// Errors that can occur when working with device auth keys.
enum DeviceAuthKeyError: Error {
    /// The device auth key is missing or invalid.
    case missingOrInvalidKey

    /// The requested functionality has not yet been implemented.
    case notImplemented
}
