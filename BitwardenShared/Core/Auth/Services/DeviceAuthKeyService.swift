import CryptoKit
import BitwardenKit
import Foundation
import os.log

import BitwardenSdk

// MARK: DeviceAuthKeyService

/// Service to manage the device passkey.
protocol DeviceAuthKeyService {
    /// Create device passkey with PRF encryption key.
    ///
    /// Before calling, vault must be unlocked to wrap user encryption key.
    ///  - Parameters:
    ///      - masterPasswordHash: Master password hash suitable for server authentication.
    ///      - overwrite: Whether to overwrite an existing value if a previous one is already found.
    ///      - userId: Currently active user ID for the account.
    func createDeviceAuthKey(
        masterPasswordHash: String,
        overwrite: Bool,
        userId: String
    ) async throws -> DeviceAuthKeyRecord
    
    /// Signs a passkey assertion request with the device auth key, if it exists and matches the given
    /// ``recordIdentifier``.
    ///
    ///  - Parameters:
    ///      - request: The passkey assertion request.
    ///      - recordIdentifier: The recordIdentifer for the ``ASPasskeyCredentialIdentity``  related to the passkey
    ///                    assertion request,  which should be equal to the cipher ID of the device auth key record.
    ///      - userId: Currently active user ID for the account.
    /// - Returns: A ``GetAssertionResult``, or ``nil`` if the device auth key does not exist.
    func assertDeviceAuthKey(
        for request: GetAssertionRequest,
        recordIdentifier: String,
        userId: String
    ) async throws -> GetAssertionResult?
    
    /// Retrieve the metadata for the device passkey, if it exists.
    ///
    ///  - Parameters:
    ///      - userId: Currently active user ID for the account.
    func getDeviceAuthKeyMetadata(userId: String) async throws -> DeviceAuthKeyMetadata?
}

/// Implementation fo DeviceAuthKeyService
struct DefaultDeviceAuthKeyService: DeviceAuthKeyService {
    // MARK: Properties

    private let clientService: ClientService
    private let keychainRepository: KeychainRepository

    // MARK: Initializers

    init(
        clientService: ClientService,
        keychainRepository: KeychainRepository,
    ) {
        self.clientService = clientService
        self.keychainRepository = keychainRepository
    }

    // MARK: Functions

    func createDeviceAuthKey(
        masterPasswordHash: String,
        overwrite: Bool,
        userId: String,
    ) async throws -> DeviceAuthKeyRecord {
        throw DeviceAuthKeyError.notImplemented
    }
    
    func assertDeviceAuthKey(
        for request: GetAssertionRequest,
        recordIdentifier: String,
        userId: String
    ) async throws -> GetAssertionResult? {
        guard let metadata = try? await getDeviceAuthKeyMetadata(userId: userId) else {
            return nil
        }
        
        guard metadata.cipherId == recordIdentifier else {
            return nil
        }
        
        guard let record = try await getDeviceAuthKeyRecord(
            keychainRepository: keychainRepository,
            userId: userId
        ) else {
            return nil
        }
        
        guard let deviceKeyB64 = try await keychainRepository.getDeviceKey(userId: userId),
              let deviceKeyData = Data(base64Encoded: deviceKeyB64) else {
            throw DeviceAuthKeyError.missingOrInvalidKey
        }
        let deviceKey = SymmetricKey(data: deviceKeyData)

        let fido2Client = try await clientService.platform().fido2()
        let result = try await fido2Client.deviceAuthenticator(
            userInterface: DeviceAuthKeyUserInterface(),
            credentialStore: DeviceAuthKeyCredentialStore(
                clientService: clientService,
                keychainRepository: keychainRepository,
                userId: userId,
            ),
            deviceKey: deviceKey
        ).getAssertion(
            request: request
        )
        return result
    }
    
    func getDeviceAuthKeyMetadata(userId: String) async throws -> DeviceAuthKeyMetadata? {
        guard let json = try? await keychainRepository.getDeviceAuthKeyMetadata(userId: userId) else {
            return nil
        }
        
        guard let jsonData = json.data(using: .utf8) else {
            return nil
        }
        
        let metadata: DeviceAuthKeyMetadata = try JSONDecoder.defaultDecoder.decode(
            DeviceAuthKeyMetadata.self,
            from: jsonData
        )
        Logger.application.debug("Metadata: \(json) })")
        return metadata
    }
    
}

enum DeviceAuthKeyError: Error {
    case notImplemented
    case missingOrInvalidKey
}

// MARK: DeviceAuthKeyCredentialStore

final internal class DeviceAuthKeyCredentialStore: Fido2CredentialStore {
    let clientService: ClientService
    let keychainRepository: KeychainRepository
    let userId: String
    
    init(clientService: ClientService, keychainRepository: KeychainRepository, userId: String) {
        self.clientService = clientService
        self.keychainRepository = keychainRepository
        self.userId = userId
    }

    func findCredentials(ids: [Data]?, ripId: String, userHandle: Data?) async throws -> [BitwardenSdk.CipherView] {
        guard let record = try? await getDeviceAuthKeyRecord(
            keychainRepository: keychainRepository,
            userId: userId
        ) else {
            return []
        }
        // record contains encrypted values; we need to decrypt them
        let encryptedCipher = record.toCipher()
        let cipherView = try await clientService.vault().ciphers().decrypt(cipher: encryptedCipher)

        let deviceKey = try await getDeviceKey()
        
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
        if let record = try? await getDeviceAuthKeyRecord(keychainRepository: keychainRepository, userId: userId) {
            // record contains encrypted values; we need to decrypt them
            let encryptedCipherView = record.toCipherView()
            let deviceKey = try await getDeviceKey()
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
        }
        return results
    }

    func saveCredential(cred: BitwardenSdk.EncryptionContext) async throws {
        if let fido2cred = cred.cipher.login?.fido2Credentials?[safeIndex: 0] {
            let record = DeviceAuthKeyRecord(
                cipherId: UUID().uuidString,
                cipherName: cred.cipher.name,
                credentialId: fido2cred.credentialId,
                keyType: fido2cred.keyType,
                keyAlgorithm: fido2cred.keyAlgorithm,
                keyCurve: fido2cred.keyCurve,
                keyValue: fido2cred.keyValue,
                rpId: fido2cred.rpId,
                rpName: fido2cred.rpName,
                userId: fido2cred.userHandle,
                userName: fido2cred.userName,
                userDisplayName: fido2cred.userDisplayName,
                counter: fido2cred.counter,
                discoverable: fido2cred.discoverable,
                // TODO(PM-26177): This requires a SDK update. This device auth key will fail to register until this is done.
                // hmacSecret: fido2cred.hmacSecret,
                hmacSecret: "",
                creationDate: cred.cipher.creationDate
            )
            let recordJson = try String(data: JSONEncoder.defaultEncoder.encode(record), encoding: .utf8)!
            // The record contains encrypted data, we need to decrypt it before storing metadata
            let deviceKey = try await SymmetricKey(
                data: Data(
                    base64Encoded: keychainRepository.getDeviceKey(
                        userId: userId
                    )!
                )!
            )
            let fido2CredentialAutofillViews = try await clientService.platform()
                .fido2()
                // TODO(PM-26177): This requires a SDK update. This device auth key will fail to decrypt for now.
                // .decryptFido2AutofillCredentials(cipherView: record.toCipherView(), encryptionKey: deviceKey)
                .decryptFido2AutofillCredentials(cipherView: record.toCipherView())

            let fido2CredentialAutofillView = fido2CredentialAutofillViews[safeIndex: 0]!
            let metadata = DeviceAuthKeyMetadata(
                credentialId: fido2CredentialAutofillView.credentialId.base64EncodedString(),
                cipherId: fido2CredentialAutofillView.cipherId,
                rpId: fido2CredentialAutofillView.rpId,
                userName: fido2CredentialAutofillView.safeUsernameForUi,
                userHandle: fido2CredentialAutofillView.userHandle.base64EncodedString(),
            )
            let metadataJson = try String(data: JSONEncoder.defaultEncoder.encode(metadata), encoding: .utf8)!

            try await keychainRepository
                .setDeviceAuthKey(
                    recordJson: recordJson,
                    metadataJson: metadataJson,
                    userId: cred.encryptedFor
                )
        }
    }
    
    private func getDeviceKey() async throws -> SymmetricKey {
        guard let deviceKeyB64 = try await keychainRepository.getDeviceKey(userId: userId),
              let deviceKeyData = Data(base64Encoded: deviceKeyB64) else {
            throw DeviceAuthKeyError.missingOrInvalidKey
        }
        return SymmetricKey(data: deviceKeyData)
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

// MARK: Private

/// Retrieve the device auth key secrets, if the record exists.
///
///  - Parameters:
///      - keychainRepository: The repository for keychain items.
///      - userId: User ID for the account to fetch.
fileprivate func getDeviceAuthKeyRecord(keychainRepository: KeychainRepository, userId: String) async throws -> DeviceAuthKeyRecord? {
    guard let json = try? await keychainRepository.getDeviceAuthKey(userId: userId) else {
        return nil
    }
    
    guard let jsonData = json.data(using: .utf8) else {
        return nil
    }
    
    let record: DeviceAuthKeyRecord = try JSONDecoder.defaultDecoder.decode(
        DeviceAuthKeyRecord.self,
        from: jsonData
    )
    Logger.application.debug("Record: \(json) })")
    return record
}
