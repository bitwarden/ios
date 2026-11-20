import BitwardenKit
import BitwardenSdk
import Combine
import Foundation
import OSLog

// MARK: - DeviceAuthKeyService

/// Service to manage the device auth key.
protocol DeviceAuthKeyService { // sourcery: AutoMockable
    /// Signs a passkey assertion request with the device auth key, if it exists and matches the given
    /// ``recordIdentifier``.
    ///
    /// - Parameters:
    ///   - request: The passkey assertion request.
    ///   - recordIdentifier: The record identifier for the ``ASPasskeyCredentialIdentity`` related to the passkey
    ///     assertion request, which should be equal to the record identifier of the device auth key.
    ///   - userId: The user ID for the account to assert the device auth key for.
    /// - Returns: A ``DeviceAuthKeyGetAssertionResult``, or `nil` if the device auth key does not exist.
    ///
    func assertDeviceAuthKey(
        for request: GetAssertionRequest,
        recordIdentifier: String,
        userId: String?,
    ) async throws -> DeviceAuthKeyGetAssertionResult?

    /// Signs a WebAuthn login challenge from the server with the device auth key of a logged out
    /// user. This reads the device auth key from the keychain, which asks the user for biometrics.
    ///
    /// - Parameter email: The email of the user that logs in.
    /// - Returns: The values for the token request and the PRF output to unlock the vault.
    ///
    func assertDeviceAuthKeyForLogin(email: String) async throws -> DeviceAuthKeyLoginResult

    /// Create device auth key with PRF encryption key.
    ///
    /// Before calling, the vault must be unlocked to wrap user encryption key.
    ///
    /// - Parameters:
    ///   - masterPassword: The user's master password (not the hash). The SDK derives the hash
    ///     that the server needs to verify the user.
    ///   - isPasswordlessAccount: Whether the device auth key is the account's primary way to log
    ///     in and unlock, because the user doesn't know the master password.
    ///   - overwrite: Whether to overwrite an existing value if a previous one is already found.
    ///   - userId: The user ID for the account to create the device auth key for.
    ///
    func createDeviceAuthKey(
        masterPassword: String,
        isPasswordlessAccount: Bool,
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
    func getDeviceAuthKeyMetadata(userId: String?) async throws -> DeviceAuthKeyKeychainMetadata?

    /// Gets the data needed to unlock the vault with the device auth key. This reads the device
    /// auth key from the keychain, which asks the user for biometrics.
    ///
    /// - Parameter userId: The user ID for the account to unlock.
    /// - Returns: The data to unlock the vault.
    ///
    func getDeviceAuthKeyUnlockData(userId: String?) async throws -> DeviceAuthKeyUnlockData

    /// Whether a device auth key exists on this device for a user with the given email. This
    /// works for logged out users.
    ///
    /// - Parameter email: The user's email.
    /// - Returns: Whether the user can log in with a device auth key.
    ///
    func hasDeviceAuthKey(email: String) async -> Bool

    /// Whether the account has a device auth key that can unlock the vault, and the user doesn't
    /// know the account's master password.
    ///
    /// - Parameter userId: The user ID for the account.
    /// - Returns: Whether the account is a device auth key account.
    ///
    func isPasswordlessAccount(userId: String?) async -> Bool

    /// Stores the PRF key set for the user's device auth key, which is needed to unlock the vault
    /// with the device auth key.
    ///
    /// - Parameters:
    ///   - encryptedPrivateKey: The private key of the key set, encrypted with the PRF key.
    ///   - encryptedUserKey: The user key, encapsulated with the public key of the key set.
    ///   - userId: The user ID for the account.
    ///
    func setDeviceAuthKeyPrfKeySet(
        encryptedPrivateKey: String,
        encryptedUserKey: String,
        userId: String?,
    ) async throws

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
    ///     assertion request, which should be equal to the record identifier of the device auth key.
    /// - Returns: A ``DeviceAuthKeyGetAssertionResult``, or `nil` if the device auth key does not exist.
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

    /// Deletes the device auth key for the current user.
    ///
    func deleteDeviceAuthKey() async throws {
        try await deleteDeviceAuthKey(userId: nil)
    }

    /// Retrieve the metadata for the device auth key for the current user, if it exists.
    ///
    func getDeviceAuthKeyMetadata() async throws -> DeviceAuthKeyKeychainMetadata? {
        try await getDeviceAuthKeyMetadata(userId: nil)
    }
}

// MARK: - DeviceAuthKeyLoginResult

/// The result of signing a WebAuthn login challenge with the device auth key.
///
struct DeviceAuthKeyLoginResult: Equatable, Sendable {
    /// The values for the identity token request and the PRF output.
    let assertion: DeviceAuthKeyLoginAssertion

    /// The ID of the user that owns the device auth key.
    let userId: String
}

// MARK: - DefaultDeviceAuthKeyService

/// Default implementation of DeviceAuthKeyService
struct DefaultDeviceAuthKeyService: DeviceAuthKeyService {
    // MARK: Properties

    /// The provider for the active account state.
    private let activeAccountStateProvider: ActiveAccountStateProvider

    /// The service that handles common client functionality such as encryption and decryption.
    private let clientService: ClientService

    /// Repository for managing device auth keys in the keychain.
    private let deviceAuthKeychainRepository: DeviceAuthKeychainRepository

    /// A subject containing a userId and flag for the presence of the unlock passkey for logged in accounts.
    private let deviceAuthKeySubject = CurrentValueSubject<[String: Bool], Never>([:])

    /// The service used by the application to manage the environment settings.
    private let environmentService: EnvironmentService

    /// The service used by the application to manage account state.
    private let stateService: StateService

    /// The object used by the application to retrieve information about this device.
    private let systemDevice: SystemDevice

    // MARK: Initializers

    /// Creates a new instance of `DefaultDeviceAuthKeyService`.
    ///
    /// - Parameters:
    ///   - activeAccountStateProvider: The provider for the active account state.
    ///   - clientService: The service that handles common client functionality.
    ///   - deviceAuthKeychainRepository: The repository for managing device auth keys in the keychain.
    ///   - environmentService: The service used by the application to manage the environment settings.
    ///   - stateService: The service used by the application to manage account state.
    ///   - systemDevice: The object used by the application to retrieve information about this device.
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
        guard let metadata = try await deviceAuthKeychainRepository.getDeviceAuthKeyMetadata(userId: resolvedUserId),
              metadata.cipherId == recordIdentifier
        else {
            return nil
        }

        let store = DefaultDeviceAuthKeyStore(
            deviceAuthKeychainRepository: deviceAuthKeychainRepository,
            userId: resolvedUserId,
        )
        return try await clientService.platform(for: resolvedUserId, isPreAuth: false)
            .fido2()
            .deviceAuthKeyAuthenticator(credentialStore: store)
            .assertDeviceAuthKey(request: request)
    }

    func assertDeviceAuthKeyForLogin(email: String) async throws -> DeviceAuthKeyLoginResult {
        guard let userId = try await deviceAuthKeychainRepository.getDeviceAuthKeyUserId(email: email) else {
            throw DeviceAuthKeyError.missingOrInvalidKey
        }
        let store = DefaultDeviceAuthKeyStore(
            deviceAuthKeychainRepository: deviceAuthKeychainRepository,
            userId: userId,
        )
        let assertion = try await clientService.platform(isPreAuth: true)
            .fido2()
            .deviceAuthKeyAuthenticator(credentialStore: store)
            .assertDeviceAuthKeyForLogin(webVaultUrl: environmentService.webVaultURL.absoluteString)
        return DeviceAuthKeyLoginResult(assertion: assertion, userId: userId)
    }

    func createDeviceAuthKey(
        masterPassword: String,
        isPasswordlessAccount: Bool,
        overwrite: Bool,
        userId: String?,
    ) async throws {
        let resolvedUserId = try await activeAccountStateProvider.userIdOrActive(userId)
        let account = try await stateService.getAccount(userId: resolvedUserId)

        if try await deviceAuthKeychainRepository.getDeviceAuthKeyMetadata(userId: resolvedUserId) != nil {
            guard overwrite else { throw DeviceAuthKeyError.alreadyExists }
            try await deviceAuthKeychainRepository.deleteDeviceAuthKey(userId: resolvedUserId)
        }

        let store = DefaultDeviceAuthKeyStore(
            deviceAuthKeychainRepository: deviceAuthKeychainRepository,
            userId: resolvedUserId,
        )
        // The SDK creates the passkey, makes the PRF key set, registers both with the server, and
        // saves the record and its metadata through the store.
        let keySet = try await clientService.platform(for: resolvedUserId, isPreAuth: false)
            .fido2()
            .deviceAuthKeyAuthenticator(credentialStore: store)
            .createDeviceAuthKey(
                clientName: "Bitwarden iOS (\(systemDevice.modelIdentifier))",
                webVaultUrl: environmentService.webVaultURL.absoluteString,
                email: account.profile.email,
                secretVerificationRequest: SecretVerificationRequest(masterPassword: masterPassword, otp: nil),
                kdf: account.kdf.sdkKdf,
            )

        try await updateMetadata(userId: resolvedUserId) { metadata in
            metadata.encryptedPrivateKey = keySet.encryptedDecapsulationKey
            metadata.encryptedUserKey = keySet.encapsulatedDownstreamKey
            metadata.isPasswordlessAccount = isPasswordlessAccount
        }
        try await deviceAuthKeychainRepository.setDeviceAuthKeyUserId(resolvedUserId, email: account.profile.email)

        var curVal = deviceAuthKeySubject.value
        curVal[resolvedUserId] = true
        deviceAuthKeySubject.send(curVal)
    }

    func deleteDeviceAuthKey(
        userId: String?,
    ) async throws {
        let resolvedUserId = try await activeAccountStateProvider.userIdOrActive(userId)
        if let metadata = try await deviceAuthKeychainRepository.getDeviceAuthKeyMetadata(userId: resolvedUserId) {
            try await deviceAuthKeychainRepository.setDeviceAuthKeyUserId(nil, email: metadata.userName)
        }
        try await deviceAuthKeychainRepository.deleteDeviceAuthKey(userId: resolvedUserId)

        var curVal = deviceAuthKeySubject.value
        curVal[resolvedUserId] = false
        deviceAuthKeySubject.send(curVal)
    }

    func getDeviceAuthKeyMetadata(userId: String?) async throws -> DeviceAuthKeyKeychainMetadata? {
        let resolvedUserId = try await activeAccountStateProvider.userIdOrActive(userId)
        return try await deviceAuthKeychainRepository.getDeviceAuthKeyMetadata(userId: resolvedUserId)
    }

    func getDeviceAuthKeyUnlockData(userId: String?) async throws -> DeviceAuthKeyUnlockData {
        let resolvedUserId = try await activeAccountStateProvider.userIdOrActive(userId)
        guard let metadata = try await deviceAuthKeychainRepository.getDeviceAuthKeyMetadata(userId: resolvedUserId),
              let encryptedPrivateKey = metadata.encryptedPrivateKey,
              let encryptedUserKey = metadata.encryptedUserKey
        else {
            throw DeviceAuthKeyError.missingPrfKeySet
        }
        let store = DefaultDeviceAuthKeyStore(
            deviceAuthKeychainRepository: deviceAuthKeychainRepository,
            userId: resolvedUserId,
        )
        // Reading the record asks the user for biometrics.
        let prfOutput = try await clientService.platform(for: resolvedUserId, isPreAuth: false)
            .fido2()
            .deviceAuthKeyAuthenticator(credentialStore: store)
            .getPrfOutput()
        return DeviceAuthKeyUnlockData(
            encryptedPrivateKey: encryptedPrivateKey,
            encryptedUserKey: encryptedUserKey,
            prfOutput: prfOutput,
        )
    }

    func hasDeviceAuthKey(email: String) async -> Bool {
        do {
            guard let userId = try await deviceAuthKeychainRepository.getDeviceAuthKeyUserId(email: email) else {
                return false
            }
            return try await deviceAuthKeychainRepository.getDeviceAuthKeyMetadata(userId: userId) != nil
        } catch {
            Logger.application.error("Device auth key lookup failed: \(error)")
            return false
        }
    }

    func isPasswordlessAccount(userId: String?) async -> Bool {
        // Not behind the feature flag: a passwordless account has no other way to unlock.
        do {
            let resolvedUserId = try await activeAccountStateProvider.userIdOrActive(userId)
            let metadata = try await deviceAuthKeychainRepository.getDeviceAuthKeyMetadata(userId: resolvedUserId)
            return metadata?.isPasswordlessAccount == true
        } catch {
            return false
        }
    }

    func setDeviceAuthKeyPrfKeySet(
        encryptedPrivateKey: String,
        encryptedUserKey: String,
        userId: String?,
    ) async throws {
        let resolvedUserId = try await activeAccountStateProvider.userIdOrActive(userId)
        try await updateMetadata(userId: resolvedUserId) { metadata in
            metadata.encryptedPrivateKey = encryptedPrivateKey
            metadata.encryptedUserKey = encryptedUserKey
        }
    }

    // MARK: Publishers

    func deviceAuthKeyPublisher() -> AnyPublisher<[String: Bool], Never> {
        deviceAuthKeySubject.eraseToAnyPublisher()
    }

    // MARK: Private

    /// Changes the stored metadata of the device auth key. Writes it only if it changed.
    ///
    /// - Parameters:
    ///   - userId: The user ID for the account.
    ///   - change: The change to make.
    ///
    private func updateMetadata(
        userId: String,
        _ change: (inout DeviceAuthKeyKeychainMetadata) -> Void,
    ) async throws {
        guard let metadata = try await deviceAuthKeychainRepository.getDeviceAuthKeyMetadata(userId: userId) else {
            throw DeviceAuthKeyError.missingOrInvalidKey
        }
        var updated = metadata
        change(&updated)
        guard updated != metadata else { return }
        try await deviceAuthKeychainRepository.setDeviceAuthKeyMetadata(updated, userId: userId)
    }
}

// MARK: - DeviceAuthKeyError

/// Errors that can occur when working with device auth keys.
enum DeviceAuthKeyError: Error {
    /// A device auth key already exists for the user.
    case alreadyExists

    /// The device auth key is missing or invalid.
    case missingOrInvalidKey

    /// The PRF key set that unlocks the vault with the device auth key is missing.
    case missingPrfKeySet
}

// MARK: - Error + DeviceAuthKey

extension Error {
    /// Whether the user cancelled the biometric check that guards the device auth key.
    var isDeviceAuthKeyCancellation: Bool {
        guard let error = self as? BitwardenSdk.BitwardenError,
              case .DeviceAuthKey(.UserCancelled) = error
        else {
            return false
        }
        return true
    }
}

// MARK: - DefaultDeviceAuthKeyStore

/// The store that the SDK uses to save and load the device auth key. It's backed by the keychain.
///
final class DefaultDeviceAuthKeyStore: DeviceAuthKeyStore, @unchecked Sendable {
    // MARK: Properties

    /// Repository for managing device auth keys in the keychain.
    private let deviceAuthKeychainRepository: DeviceAuthKeychainRepository

    /// The ID of the user that owns the device auth key.
    private let userId: String

    // MARK: Initialization

    /// Creates a new `DefaultDeviceAuthKeyStore`.
    ///
    /// - Parameters:
    ///   - deviceAuthKeychainRepository: Repository for managing device auth keys in the keychain.
    ///   - userId: The ID of the user that owns the device auth key.
    ///
    init(
        deviceAuthKeychainRepository: DeviceAuthKeychainRepository,
        userId: String,
    ) {
        self.deviceAuthKeychainRepository = deviceAuthKeychainRepository
        self.userId = userId
    }

    // MARK: DeviceAuthKeyStore

    func createRecord(record: DeviceAuthKeyRecord) async throws {
        let keychainRecord = DeviceAuthKeyKeychainRecord(
            counter: record.counter,
            credentialId: record.credentialId,
            hmacSecret: record.hmacSecret,
            key: record.key,
            rpId: record.rpId,
            userId: record.userId,
        )
        try await deviceAuthKeychainRepository.setDeviceAuthKeyRecord(keychainRecord, userId: userId)
    }

    func createMetadata(metadata: DeviceAuthKeyMetadata) async throws {
        try await deviceAuthKeychainRepository.setDeviceAuthKeyMetadata(
            DeviceAuthKeyKeychainMetadata(
                cipherId: metadata.recordIdentifier,
                creationDate: metadata.creationDate,
                credentialId: metadata.credentialId,
                rpId: metadata.rpId,
                userDisplayName: metadata.userDisplayName,
                userHandle: metadata.userHandle,
                userName: metadata.userName,
            ),
            userId: userId,
        )
    }

    func getMetadata() async throws -> DeviceAuthKeyMetadata? {
        guard let metadata = try await deviceAuthKeychainRepository.getDeviceAuthKeyMetadata(userId: userId) else {
            return nil
        }
        return DeviceAuthKeyMetadata(
            recordIdentifier: metadata.cipherId,
            creationDate: metadata.creationDate ?? .distantPast,
            credentialId: metadata.credentialId,
            rpId: metadata.rpId,
            userName: metadata.userName,
            userHandle: metadata.userHandle,
            userDisplayName: metadata.userDisplayName ?? metadata.userName,
        )
    }

    func getRecord() async throws -> DeviceAuthKeyRecord? {
        let keychainRecord: DeviceAuthKeyKeychainRecord?
        do {
            keychainRecord = try await deviceAuthKeychainRepository.getDeviceAuthKey(userId: userId)
        } catch let KeychainServiceError.osStatusError(status) where status == errSecUserCanceled {
            // The SDK returns this error as is, so the app can tell a cancel from a failure.
            throw DeviceAuthKeyCallbackError.UserCancelled
        }
        guard let keychainRecord else { return nil }
        return DeviceAuthKeyRecord(
            credentialId: keychainRecord.credentialId,
            key: keychainRecord.key,
            rpId: keychainRecord.rpId,
            userId: keychainRecord.userId,
            // The SDK's store can't update the counter, and an assertion with a counter fails in
            // the SDK. The device auth key doesn't use signature counters.
            counter: nil,
            hmacSecret: keychainRecord.hmacSecret,
        )
    }

    func deleteRecordAndMetadata() async throws {
        try await deviceAuthKeychainRepository.deleteDeviceAuthKey(userId: userId)
    }
}
