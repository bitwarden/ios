import CryptoKit
import BitwardenKit
import BitwardenSdk
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

    private let clientService: ClientService

    /// Repository for managing device auth keys in the keychain.
    private let deviceAuthKeychainRepository: DeviceAuthKeychainRepository

    /// Repository for managing keys in the keychain.
    private let keychainRepository: KeychainRepository

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
        keychainRepository: KeychainRepository,
    ) {
        self.activeAccountStateProvider = activeAccountStateProvider
        self.clientService = clientService
        self.deviceAuthKeychainRepository = deviceAuthKeychainRepository
        self.keychainRepository = keychainRepository
    }

    // MARK: Functions

    func assertDeviceAuthKey(
        for request: GetAssertionRequest,
        recordIdentifier: String,
        userId: String?,
    ) async throws -> GetAssertionResult? {
        let userId = try await activeAccountStateProvider.userIdOrActive(userId)
        guard let metadata = try? await getDeviceAuthKeyMetadata(userId: userId) else {
            return nil
        }

        guard request.rpId == environmentService.webVaultURL.domain else {
            throw DeviceAuthKeyError.invalidRequest(reason: "Requested RP ID does not match expected origin")
        }

        guard metadata.cipherId == recordIdentifier else {
            return nil
        }

        guard try await deviceAuthKeychainRepository.getDeviceAuthKey(userId: userId) != nil else {
            return nil
        }

        guard let deviceKeyB64 = try await keychainRepository.getDeviceKey(userId: userId),
              let deviceKeyData = Data(base64Encoded: deviceKeyB64) else {
            throw DeviceAuthKeyError.missingOrInvalidKey
        }
        let deviceKey = SymmetricKey(data: deviceKeyData)

        let fido2Client = try await clientService.platform().fido2()
        return try await fido2Client.deviceAuthenticator(
            userInterface: DeviceAuthKeyUserInterface(),
            credentialStore: DeviceAuthKeyCredentialStore(
                clientService: clientService,
                deviceAuthKeychainRepository: deviceAuthKeychainRepository,
                deviceKey: deviceKey,
                userId: userId,
            ),
            deviceKey: deviceKey,
        ).getAssertion(
            request: request,
        )
    }

    func createDeviceAuthKey(
        masterPasswordHash: String,
        overwrite: Bool,
        userId: String?,
    ) async throws -> DeviceAuthKeyRecord {
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
}

// MARK: - DeviceAuthKeyError

/// Errors that can occur when working with device auth keys.
enum DeviceAuthKeyError: Error {
    /// An invalid cipher was returned from the SDK.
    case invalidCipher

    /// The device auth key is missing or invalid.
    case missingOrInvalidKey

    /// The requested functionality has not yet been implemented.
    case notImplemented
}

// MARK: DeviceAuthKeyCredentialStore

final internal class DeviceAuthKeyCredentialStore: Fido2CredentialStore {
    let clientService: ClientService
    let deviceAuthKeychainRepository: DeviceAuthKeychainRepository
    let deviceKey: SymmetricKey
    let userId: String

    init(clientService: ClientService, deviceAuthKeychainRepository: DeviceAuthKeychainRepository, deviceKey: SymmetricKey, userId: String) {
        self.clientService = clientService
        self.deviceAuthKeychainRepository = deviceAuthKeychainRepository
        self.deviceKey = deviceKey
        self.userId = userId
    }

    func findCredentials(ids: [Data]?, ripId: String, userHandle: Data?) async throws -> [BitwardenSdk.CipherView] {
        guard let record = try? await deviceAuthKeychainRepository.getDeviceAuthKey(userId: userId) else {
            return []
        }
        // record contains encrypted values; we need to decrypt them
        let encryptedCipher = record.toCipher()
        let cipherView = try await clientService.vault().ciphers().decrypt(cipher: encryptedCipher)

        let fido2CredentialAutofillViews = try await clientService.platform()
            .fido2()
            // TODO(PM-26177): This requires a SDK update. This will fail to decrypt until that is implemented.
            // .decryptFido2AutofillCredentials(cipherView: cipherView, encryptionKey: deviceKey)
            .decryptFido2AutofillCredentials(cipherView: cipherView)

        guard let fido2CredentialAutofillView = fido2CredentialAutofillViews[safeIndex: 0],
              ripId == fido2CredentialAutofillView.rpId else {
            return []
        }

        if let ids,
           !ids.contains(fido2CredentialAutofillView.credentialId) {
            return []
        }

        if let userHandle,
           fido2CredentialAutofillView.userHandle != userHandle {
            return []
        }

        return [cipherView]
    }

    func allCredentials() async throws -> [BitwardenSdk.CipherListView] {
        var results: [BitwardenSdk.CipherListView] = []
        guard let record = try? await deviceAuthKeychainRepository.getDeviceAuthKey(userId: userId) else {
            return results
        }
        // record contains encrypted values; we need to decrypt them
        let encryptedCipherView = record.toCipherView()
        let decrypted = try await clientService.vault().ciphers()
            .decryptFido2Credentials(cipherView: encryptedCipherView)[0]
            // TODO(PM-26177): This requires a SDK update. This will fail to decrypt until that is implemented.
            // .decryptFido2Credentials(cipherView: encryptedCipherView, encryptionKey: deviceKey)[0]

        let fido2View = Fido2CredentialListView(
            credentialId: decrypted.credentialId,
            rpId: decrypted.rpId,
            userHandle: decrypted.userHandle,
            userName: decrypted.userName,
            userDisplayName: decrypted.userDisplayName,
            counter: decrypted.counter
        )
        let loginView = BitwardenSdk.LoginListView(
            fido2Credentials: [fido2View],
            hasFido2: true,
            username: decrypted.userDisplayName,
            totp: nil,
            uris: nil
        )

        let cipherView = CipherListView(
            id: record.cipherId,
            organizationId: nil,
            folderId: nil,
            collectionIds: [],
            key: nil, // setting the key to null means that it will be encrypted by the user key directly.
            name: record.cipherName,
            subtitle: "Vault passkey created by Bitwarden app",
            type: CipherListViewType.login(loginView),
            favorite: false,
            reprompt: BitwardenSdk.CipherRepromptType.none,
            organizationUseTotp: false,
            edit: false,
            permissions: nil,
            viewPassword: false,
            attachments: 0,
            hasOldAttachments: false,
            creationDate: record.creationDate,
            deletedDate: nil,
            revisionDate: record.creationDate,
            archivedDate: nil,
            copyableFields: [],
            localData: nil
        )
        results.append(cipherView)
        return results
    }

    func saveCredential(cred: BitwardenSdk.EncryptionContext) async throws {
        guard let fido2cred = cred.cipher.login?.fido2Credentials?[safeIndex: 0] else {
            throw DeviceAuthKeyError.invalidCipher
        }
        let record = DeviceAuthKeyRecord(
            cipherId: UUID().uuidString,
            cipherName: cred.cipher.name,
            counter: fido2cred.counter,
            creationDate: cred.cipher.creationDate,
            credentialId: fido2cred.credentialId,
            discoverable: fido2cred.discoverable,
            // TODO(PM-26177): This requires a SDK update. This device auth key will fail to register until this is done.
            // hmacSecret: fido2cred.hmacSecret,
            hmacSecret: "",
            keyAlgorithm: fido2cred.keyAlgorithm,
            keyCurve: fido2cred.keyCurve,
            keyType: fido2cred.keyType,
            keyValue: fido2cred.keyValue,
            rpId: fido2cred.rpId,
            rpName: fido2cred.rpName,
            userDisplayName: fido2cred.userDisplayName,
            userId: fido2cred.userHandle,
            userName: fido2cred.userName,
        )

        // The record contains encrypted data, we need to decrypt it before storing metadata
        let fido2CredentialAutofillViews = try await clientService.platform()
            .fido2()
        // TODO(PM-26177): This requires a SDK update. This device auth key will fail to decrypt for now.
        // .decryptFido2AutofillCredentials(cipherView: record.toCipherView(), encryptionKey: deviceKey)
            .decryptFido2AutofillCredentials(cipherView: record.toCipherView())

        let fido2CredentialAutofillView = fido2CredentialAutofillViews[safeIndex: 0]!
        let metadata = DeviceAuthKeyMetadata(
            cipherId: fido2CredentialAutofillView.cipherId,
            credentialId: fido2CredentialAutofillView.credentialId,
            rpId: fido2CredentialAutofillView.rpId,
            userHandle: fido2CredentialAutofillView.userHandle,
            userName: fido2CredentialAutofillView.safeUsernameForUi,
        )

        try await deviceAuthKeychainRepository
            .setDeviceAuthKey(
                record: record,
                metadata: metadata,
                userId: cred.encryptedFor
            )
    }
}


// MARK: DeviceAuthKeyUserInterface

final class DeviceAuthKeyUserInterface: Fido2UserInterface {
    func checkUser(
        options: BitwardenSdk.CheckUserOptions,
        hint: BitwardenSdk.UiHint
    ) async throws -> BitwardenSdk.CheckUserResult {
        // If we have gotten this far, we have decrypted the credential using Keychain verification methods, so we
        // assume the user is present and verified.
        BitwardenSdk.CheckUserResult(userPresent: true, userVerified: true)
    }

    func pickCredentialForAuthentication(
        availableCredentials: [BitwardenSdk.CipherView]
    ) async throws -> BitwardenSdk.CipherViewWrapper {
        guard availableCredentials.count == 1 else {
            throw Fido2Error.invalidOperationError
        }
        return BitwardenSdk.CipherViewWrapper(cipher: availableCredentials[0])
    }

    func checkUserAndPickCredentialForCreation(
        options: BitwardenSdk.CheckUserOptions,
        newCredential: BitwardenSdk.Fido2CredentialNewView
    ) async throws -> BitwardenSdk.CheckUserAndPickCredentialForCreationResult {
        BitwardenSdk
            .CheckUserAndPickCredentialForCreationResult(
                cipher: CipherViewWrapper(
                    cipher: CipherView(
                        fido2CredentialNewView: newCredential,
                        timeProvider: CurrentTime()
                    )
                ),
                checkUserResult: CheckUserResult(
                    userPresent: true,
                    userVerified: true
                )
            )
    }

    func isVerificationEnabled() -> Bool {
        true
    }
}
