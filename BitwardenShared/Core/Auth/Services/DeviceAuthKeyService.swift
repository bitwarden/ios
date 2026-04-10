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
    ) async throws -> DeviceAuthKeyGetAssertionResult?

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
    ) async throws

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
    ) async throws -> DeviceAuthKeyGetAssertionResult? {
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
    ) async throws {
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

    private let clientService: ClientService

    /// Repository for managing device auth keys in the keychain.
    private let deviceAuthKeychainRepository: DeviceAuthKeychainRepository

    /// A subject containing a userId and flag for the presence of the unlock passkey for logged in accounts.
    private let deviceAuthKeySubject = CurrentValueSubject<[String: Bool], Never>([:])

    private let environmentService: EnvironmentService

    private let stateService: StateService

    private let systemDevice: SystemDevice

    // MARK: Initializers

    /// Creates a new instance of `DefaultDeviceAuthKeyService`.
    ///
    /// - Parameters:
    ///   - activeAccountStateProvider: The provider for the active account state.
    ///   - deviceAuthKeychainRepository: The repository for managing device auth keys in the keychain.
    ///
    init(
        activeAccountStateProvider: ActiveAccountStateProvider,
        clientService: ClientService,
        deviceAuthKeychainRepository: DeviceAuthKeychainRepository,
        environmentService: EnvironmentService,
        stateService: StateService,
        systemDevice: SystemDevice,
    ) {
        self.activeAccountStateProvider = activeAccountStateProvider
        self.clientService = clientService
        self.deviceAuthKeychainRepository = deviceAuthKeychainRepository
        self.environmentService = environmentService
        self.stateService = stateService
        self.systemDevice = systemDevice
    }

    // MARK: Functions

    func assertDeviceAuthKey(
        for request: GetAssertionRequest,
        recordIdentifier: String,
        userId: String?,
    ) async throws -> DeviceAuthKeyGetAssertionResult? {
        let resolvedUserId = try await activeAccountStateProvider.userIdOrActive(userId)

        let store = DefaultDeviceAuthKeyStore(
            deviceAuthKeychainRepository: deviceAuthKeychainRepository,
            userId: resolvedUserId
        )
        let authenticator = try await clientService.platform().fido2().deviceAuthKeyAuthenticator(
            credentialStore: store
        )
        return try await authenticator.assertDeviceAuthKey(request: request)
    }

    func createDeviceAuthKey(
        masterPasswordHash: String,
        overwrite: Bool,
        userId: String?,
    ) async throws {
        let resolvedUserId = try await activeAccountStateProvider.userIdOrActive(userId)
        let account = try await stateService.getAccount(userId: resolvedUserId)

        let store = DefaultDeviceAuthKeyStore(
            deviceAuthKeychainRepository: deviceAuthKeychainRepository,
            userId: resolvedUserId
        )
        let authenticator = try await clientService.platform().fido2().deviceAuthKeyAuthenticator(
            credentialStore: store
        )
        let secretVerificationRequest = SecretVerificationRequest(masterPassword: masterPasswordHash, otp: nil)
        try await authenticator.createDeviceAuthKey(
            clientName: "Bitwarden on \(systemDevice.modelIdentifier)",
            webVaultUrl: environmentService.webVaultURL.absoluteString,
            email: account.profile.email,
            secretVerificationRequest: secretVerificationRequest,
            kdf: account.kdf.sdkKdf,
        )

        var curVal = deviceAuthKeySubject.value
        curVal[resolvedUserId] = true
        deviceAuthKeySubject.send(curVal)
    }

    func deleteDeviceAuthKey(
        userId: String?,
    ) async throws {
        let resolvedUserId = try await activeAccountStateProvider.userIdOrActive(userId)

        var curVal = deviceAuthKeySubject.value
        curVal[resolvedUserId] = false
        deviceAuthKeySubject.send(curVal)

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


class DefaultDeviceAuthKeyStore: DeviceAuthKeyStore {

    private let deviceAuthKeychainRepository: DeviceAuthKeychainRepository
    private let userId: String

    init(deviceAuthKeychainRepository: DeviceAuthKeychainRepository, userId: String) {
        self.deviceAuthKeychainRepository = deviceAuthKeychainRepository
        self.userId = userId
    }

    func createRecord(record: BitwardenSdk.DeviceAuthKeyRecord) async throws {
        let ourRecord = BitwardenShared.DeviceAuthKeyRecord(
            counter: record.counter ?? 0,
            credentialId: record.credentialId,
            hmacSecret: record.hmacSecret,
            keyAlgorithm: record.keyAlg,
            keyCurve: record.keyCurve,
            keyValue: record.key,
            rpId: record.rpId,
            rpName: record.rpId,
            userId: record.userId,
        )
        try await deviceAuthKeychainRepository.setDeviceAuthKeyRecord(record: ourRecord, userId: userId)
    }

    func createMetadata(metadata: BitwardenSdk.DeviceAuthKeyMetadata) async throws {
        let ourMetadata = BitwardenShared.DeviceAuthKeyMetadata(
            creationDate: metadata.creationDate,
            credentialId: metadata.credentialId,
            recordIdentifier: metadata.recordIdentifier,
            rpId: metadata.rpId,
            userDisplayName: metadata.userDisplayName,
            userHandle: metadata.userHandle,
            userName: metadata.userName,
        )
        try await deviceAuthKeychainRepository.setDeviceAuthKeyMetadata(metadata: ourMetadata, userId: userId)
    }

    func getMetadata() async throws -> BitwardenSdk.DeviceAuthKeyMetadata? {
        guard let ourMetadata = try await deviceAuthKeychainRepository.getDeviceAuthKeyMetadata(userId: userId) else {
            return nil
        }
        return BitwardenSdk.DeviceAuthKeyMetadata(
            recordIdentifier: ourMetadata.recordIdentifier,
            creationDate: ourMetadata.creationDate,
            credentialId: ourMetadata.credentialId,
            rpId: ourMetadata.rpId,
            userName: ourMetadata.userName,
            userHandle: ourMetadata.userHandle,
            userDisplayName: ourMetadata.userName,
        )
    }

    func getRecord() async throws -> BitwardenSdk.DeviceAuthKeyRecord? {
        guard let ourRecord = try await deviceAuthKeychainRepository.getDeviceAuthKey(userId: userId) else {
            return nil
        }

        return BitwardenSdk
            .DeviceAuthKeyRecord(
                credentialId: Data(base64Encoded: ourRecord.credentialId)!,
                key: Data(base64Encoded: ourRecord.keyValue)!,
                keyAlg: -7,
                keyCurve: 1,
                rpId: ourRecord.rpId,
                userId: ourRecord.userId,
                counter: UInt32(ourRecord.counter),
                hmacSecret: ourRecord.hmacSecret,
            )
    }

    func deleteRecordAndMetadata() async throws {
        try await deviceAuthKeychainRepository.deleteDeviceAuthKey(userId: userId)
    }
}
