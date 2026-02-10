import CryptoKit
import BitwardenKit
import Foundation
import os.log
import UIKit

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
    ) async throws
    
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

    private let authAPIService: AuthAPIService
    private let clientService: ClientService
    private let environmentService: EnvironmentService
    private let keychainRepository: KeychainRepository
    
    /// Default PRF salt input to use if none is received from WebAuthn client.
    private static let defaultLoginWithPrfSalt = Data(SHA256.hash(data: "passwordless-login".data(using: .utf8)!))
    
    // MARK: Initializers

    init(
        authAPIService: AuthAPIService,
        clientService: ClientService,
        environmentService: EnvironmentService,
        keychainRepository: KeychainRepository,
    ) {
        self.authAPIService = authAPIService
        self.clientService = clientService
        self.environmentService = environmentService
        self.keychainRepository = keychainRepository
    }

    // MARK: Functions

    func createDeviceAuthKey(
        masterPasswordHash: String,
        overwrite: Bool,
        userId: String,
    ) async throws {
        let record = try? await getDeviceAuthKeyRecord(keychainRepository: keychainRepository, userId: userId)
        guard record == nil || overwrite else {
            return
        }
        let deviceKey = try await ensureDeviceKeyIsSet(userId: userId)
                                                                                                                       
        // Create passkey from server options
        let response = try await authAPIService.getWebAuthnCredentialCreationOptions(
            SecretVerificationRequestModel(masterPasswordHash: masterPasswordHash)
        )
        let options = response.options
        let token = response.token
        let (createdCredential, clientDataJson) = try await createPasskey(
            options: options,
            userId: userId,
            deviceKey: deviceKey
        )
                                                                                                                       
        // Create unlock keyset from PRF value
        // TODO(PM-26177): Extensions will be returned in an SDK update
        // let prfResult = createdCredential.extensions.prf!.results!.first
        let prfResult = Data()
        let prfKeyResponse = try await clientService.crypto().makePrfUserKeySet(prf: prfResult.base64EncodedString())
                                                                                                                       
        // Register the credential keyset with the server.
        // TODO: This only returns generic names like `iPhone` on real devices.
        // If there is a more specific name available (e.g., user-chosen),
        // that would be helpful to disambiguate in the menu.
        let clientName = await "Bitwarden App on \(UIDevice.current.name)"
        guard let clientDataJsonData = clientDataJson.data(using: .utf8) else {
            throw DeviceAuthKeyError.serialization(reason: "Failed to serialize clientDataJson to data")
        }
        
        let request = WebAuthnLoginSaveCredentialRequestModel(
            deviceResponse: WebAuthnPublicKeyCredentialWithAttestationResponse(
                id: createdCredential.credentialId.base64UrlEncodedString(trimPadding: false),
                rawId: createdCredential.credentialId.base64UrlEncodedString(trimPadding: false),
                response: WebAuthnAuthenticatorAttestationResponse(
                    attestationObject: createdCredential.attestationObject.base64UrlEncodedString(trimPadding: false),
                    clientDataJson: clientDataJson.data(using: .utf8)!.base64UrlEncodedString(trimPadding: false)
                ),
                type: "public-key"
            ),
            encryptedUserKey: prfKeyResponse.encapsulatedDownstreamKey,
            encryptedPublicKey: prfKeyResponse.encryptedEncapsulationKey,
            encryptedPrivateKey: prfKeyResponse.encryptedDecapsulationKey,
            name: clientName,
            supportsPrf: true,
            token: token
        )
        try await authAPIService.saveWebAuthnCredential(request)
    }
    
    func assertDeviceAuthKey(
        for request: GetAssertionRequest,
        recordIdentifier: String,
        userId: String
    ) async throws -> GetAssertionResult? {
        guard let metadata = try? await getDeviceAuthKeyMetadata(userId: userId) else {
            return nil
        }

        guard let rpId = environmentService.webVaultURL.domain else {
            throw DeviceAuthKeyError.invalidRequest(reason: "Requested RP ID does not match expected origin")
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
    
    // MARK: Private
    
    private func createPasskey(
        options: WebAuthnPublicKeyCredentialCreationOptions,
        userId: String,
        deviceKey: SymmetricKey
    ) async throws -> (MakeCredentialResult, String) {
        let excludeCredentials: [PublicKeyCredentialDescriptor]? = if options.excludeCredentials != nil {
            // TODO: return early if exclude credentials matches
            try options.excludeCredentials!.map { params in
                try PublicKeyCredentialDescriptor(
                    ty: params.type,
                    id: Foundation.Data(base64UrlEncoded: params.id)!,
                    transports: nil
                )
            }
        } else { nil }
                                                                                                                       
        let credParams = options.pubKeyCredParams.map { params in
            PublicKeyCredentialParameters(ty: params.type, alg: Int64(params.alg))
        }
                                                                                                                       
        let origin = deriveWebOrigin()
        // Manually serialize to JSON to make sure it's ordered and formatted according to the spec.
        let clientDataJson = #"{"type":"webauthn.create","challenge":"\#(options.challenge)","origin":"\#(origin)"}"#
        let clientDataHash = Data(SHA256.hash(data: clientDataJson.data(using: .utf8)!))
                                                                                                                       
        let credRequest = try MakeCredentialRequest(
            clientDataHash: clientDataHash,
            rp: PublicKeyCredentialRpEntity(id: options.rp.id, name: options.rp.name),
            user: PublicKeyCredentialUserEntity(
                id: Data(base64UrlEncoded: options.user.id)!,
                displayName: options.user.name,
                name: options.user.name
            ),
            pubKeyCredParams: credParams,
            excludeList: excludeCredentials,
            options: Options(
                rk: true,
                uv: .required
            ),
            extensions: #"{"prf":{"eval":{"first":"\#(DefaultDeviceAuthKeyService.defaultLoginWithPrfSalt)"}}}"#,
        )
        let authenticator = DeviceAuthKeyAuthenticator(keychainRepository: keychainRepository, userId: userId)
        let (createdCredential, prfResult) = try await authenticator.makeCredential(request: credRequest)
        return (createdCredential, clientDataJson)
    }

    private func deriveWebOrigin() -> String {
        // TODO: Should we be using the web vault as the origin, and is this the best way to get it?
        let url = environmentService.webVaultURL
        return "\(url.scheme ?? "http")://\(url.hostWithPort!)"
    }
    
    private func ensureDeviceKeyIsSet(userId: String) async throws -> SymmetricKey {
        guard let deviceKey = try await getDeviceKey(keychainRepository: keychainRepository, userId: userId) else {
            let deviceKey = SymmetricKey(size: SymmetricKeySize(bitCount: 512))
            let key = deviceKey.withUnsafeBytes { bytes in
                Data(Array(bytes)).base64EncodedString()
            }
            try await keychainRepository.setDeviceKey(key, userId: userId)
        }
        return deviceKey
    }

}

enum DeviceAuthKeyError: Error {
    case invalidRequest(reason: String)
    case notImplemented
    case missingOrInvalidKey
    case missingPrfInput
    case serialization(reason: String)
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

        guard let deviceKey = try await getDeviceKey(keychainRepository: keychainRepository, userId: userId) else {
            return []
        }
        
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
            guard let deviceKey = try await getDeviceKey(keychainRepository: keychainRepository, userId: userId) else {
                return []
            }
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
        guard let fido2cred = cred.cipher.login?.fido2Credentials?[safeIndex: 0],
              let userHandle = fido2cred.userHandle,
              let userName = fido2cred.userName,
              let userDisplayName = fido2cred.userDisplayName else {
        }
        let record = DeviceAuthKeyRecord(
            cipherId: UUID().uuidString,
            cipherName: cred.cipher.name,
            credentialId: fido2cred.credentialId,
            keyType: fido2cred.keyType,
            keyAlgorithm: fido2cred.keyAlgorithm,
            keyCurve: fido2cred.keyCurve,
            keyValue: fido2cred.keyValue,
            rpId: fido2cred.rpId,
            rpName: fido2cred.rpName ?? fido2cred.rpId,
            userId: userHandle,
            userName: userName,
            userDisplayName: userDisplayName,
            counter: fido2cred.counter,
            discoverable: fido2cred.discoverable,
            // TODO(PM-26177): This requires a SDK update. This device auth key will fail to register until this is done.
            // hmacSecret: fido2cred.hmacSecret,
            hmacSecret: "",
            creationDate: cred.cipher.creationDate
        )
        let recordJson = try String(data: JSONEncoder.defaultEncoder.encode(record), encoding: .utf8)!
        // The record contains encrypted data, we need to decrypt it before storing metadata
        guard let deviceKey = try await getDeviceKey(keychainRepository: keychainRepository, userId: userId) else {
            throw DeviceAuthKeyError.missingOrInvalidKey
        }
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

fileprivate func getDeviceKey(keychainRepository: KeychainRepository, userId: String) async throws -> SymmetricKey? {
    // TODO(PM-26177): Confirm with KM whether we can reuse the device key or if we should set a separate key.
    guard let deviceKeyB64 = try await keychainRepository.getDeviceKey(userId: userId),
          let deviceKeyData = Data(base64Encoded: deviceKeyB64) else {
        return nil
    }
    return SymmetricKey(data: deviceKeyData)
}

// MARK: - DeviceAuthKeyAuthenticator

// This is a temporary implementation for the device authenticator that will eventually move to the SDK.
private class DeviceAuthKeyAuthenticator {
    /// This is the AAGUID for the Bitwarden Passkey provider (d548826e-79b4-db40-a3d8-11116f7e8349)
    /// It is used for the Relaying Parties to identify the authenticator during registration
    private let aaguid = Data([
        0xd5, 0x48, 0x82, 0x6e, 0x79, 0xb4, 0xdb, 0x40, 0xa3, 0xd8, 0x11, 0x11, 0x6f, 0x7e, 0x83, 0x49,
    ]);
    
    /// Default PRF salt input to use if none is received from WebAuthn client.
    private let defaultLoginWithPrfSalt = Data(SHA256.hash(data: "passwordless-login".data(using: .utf8)!))

    private let keychainRepository: KeychainRepository
    private let userId: String

    init(keychainRepository: KeychainRepository, userId: String) {
        self.keychainRepository = keychainRepository
    }

    func makeCredential(request: MakeCredentialRequest) async throws -> (MakeCredentialResult, Data) {
        // attested credential data
        let credId = try getSecureRandomBytes(count: 32)
        let privKey = P256.Signing.PrivateKey(compactRepresentable: false)
        let publicKeyBytes = privKey.publicKey.rawRepresentation
        let pointX = publicKeyBytes[1..<33]
        let pointY = publicKeyBytes[33...]
        var cosePubKey = Data()
        cosePubKey.append(contentsOf: [
            0xA5, // Map, length 5
            0x01, 0x02, // 1 (kty): 2 (EC2)
            0x03,  0x26, // 3 (alg): -7 (ES256)
            0x20,  0x01, // -1 (crv): 1 (P256)
        ])
        cosePubKey.append(contentsOf: [
            0x21, 0x58, 0x20// -2 (x): bytes, len 32
        ])
        cosePubKey.append(contentsOf: pointX)
        cosePubKey.append(contentsOf: [
            0x22, 0x58, 0x20// -3 (x): bytes, len 32
        ])
        cosePubKey.append(contentsOf: pointY)
        // https://www.w3.org/TR/webauthn-3/#sctn-attested-credential-data
        let attestedCredentialData = aaguid + UInt16(credId.count).bytes + credId + cosePubKey

        let extInput: WebAuthnAuthenticationExtensionsClientInputs? = if let ext = request.extensions {
            try? JSONDecoder.defaultDecoder.decode(
                WebAuthnAuthenticationExtensionsClientInputs.self,
                from: Data(
                    ext.utf8
                )
            ) }
        else {
            nil
        }

        // PRF
        // We're processing this as a WebAuthn extension, not a CTAP2 extension,
        // so we're not writing this to the extension data in the authenticator data.
        guard let prfInputB64 = extInput?.prf?.eval?.first,
              let prfInput = Data(base64UrlEncoded: prfInputB64) else {
            throw DeviceAuthKeyError.missingPrfInput
        }
        let prfSeed = SymmetricKey(size: SymmetricKeySize(bitCount: 256))
        let prfResult = generatePrf(using: prfInput, from: prfSeed)

        // authenticatorData
        let authData = buildAuthenticatorData(rpId: request.rp.id, attestedCredentialData: attestedCredentialData)

        // signature
        let response = try createAttestationObject(
            withKey: privKey,
            authenticatorData: authData,
            clientDataHash: request.clientDataHash)
        let result = MakeCredentialResult(
            authenticatorData: authData,
            attestationObject: response.attestationObject,
            credentialId: credId)
        let prfSeedB64 = prfSeed.withUnsafeBytes { bytes in
            Data(Array(bytes)).base64EncodedString()
        }
        let record = DeviceAuthKeyRecord(
            cipherId: UUID().uuidString,
            cipherName: "Device Auth Key",
            credentialId: result.credentialId.base64EncodedString(),
            keyType: "public-key",
            keyAlgorithm: "-7",
            keyCurve: "P-256",
            keyValue: privKey.rawRepresentation.base64EncodedString(),
            rpId: request.rp.id,
            rpName: request.rp.name ?? request.rp.id,
            userId: request.user.id.base64EncodedString(),
            userName: request.user.name,
            userDisplayName: request.user.displayName,
            counter: "0",
            discoverable: "true",
            hmacSecret: prfSeedB64,
            creationDate: Date()
        )
        let metadata = DeviceAuthKeyMetadata(
            credentialId: record.credentialId,
            cipherId: record.cipherId,
            rpId: record.rpId,
            userName: request.user.name,
            userHandle: request.user.id.base64EncodedString()
        )
        let recordJson = try JSONEncoder.defaultEncoder.encode(record).base64EncodedString()
        let metadataJson = try JSONEncoder.defaultEncoder.encode(metadata).base64EncodedString()
        try await keychainRepository.setDeviceAuthKey(recordJson: recordJson, metadataJson: metadataJson, userId: userId)
        return (result, prfResult)
    }

    /// Use device auth key to assert a credential, outputting PRF output.
    func getAssertion(request: GetAssertionRequest) async throws -> (GetAssertionResult, Data?)? {
        guard let json = try? await keychainRepository.getDeviceAuthKey(userId: userId),
              let jsonData = json.data(using: .utf8)
        else {
            Logger.application.warning("Matched Bitwarden Web Vault rpID, but no device passkey found.")
            throw DeviceAuthKeyError.missingOrInvalidKey
        }
        let record: DeviceAuthKeyRecord = try JSONDecoder.defaultDecoder.decode(DeviceAuthKeyRecord.self, from: jsonData)

        // extensions
        // prf
        let prfInput = if let extJson = request.extensions,
           let extJsonData = extJson.data(using: .utf8),
           let extInputs = try? JSONDecoder.defaultDecoder.decode(WebAuthnAuthenticationExtensionsClientInputs.self, from: extJsonData),
           let prfEval = extInputs.prf?.eval
        {
            Data(base64UrlEncoded: prfEval.first)
        } else {
            defaultLoginWithPrfSalt
        }

        guard let prfSeedData = Data(base64Encoded: record.hmacSecret) else {
            DeviceAuthKeyError.missingOrInvalidKey
        }
        let prfSeed = SymmetricKey(data: prfSeedData)


        // TODO: this is unused, but appears in GetAssertionResult signature.
        let fido2View = Fido2CredentialView(
            credentialId: record.credentialId,
            keyType: "public-key",
            keyAlgorithm: "ECDSA",
            keyCurve: "P-256",
            keyValue: EncString(),
            rpId: record.rpId,
            userHandle: nil,
            userName: nil,
            counter: "0",
            rpName: nil,
            userDisplayName: nil,
            discoverable: "true",
            creationDate: record.creationDate,
        )
        let fido2NewView = Fido2CredentialNewView(
            credentialId: record.credentialId,
            keyType: "public-key",
            keyAlgorithm: "ECDSA",
            keyCurve: "P-256",
            rpId: record.rpId,
            userHandle: nil,
            userName: nil,
            counter: "0",
            rpName: nil,
            userDisplayName: nil,
            creationDate: record.creationDate,
        )
        guard let credId = Data(base64Encoded: record.credentialId),
              let userHandle = Data(base64Encoded: record.userId),
            let privKeyB64 = Data(base64Encoded: record.keyValue) else {
            throw DeviceAuthKeyError.missingOrInvalidKey
        }
        let privKey = try P256.Signing.PrivateKey(rawRepresentation: privKeyB64)
        let assertion = try assertWebAuthnCredential(
            withKey: privKey,
            rpId: request.rpId,
            clientDataHash: request.clientDataHash,
            prfSeed: prfSeed,
            prfInput: prfInput)
        let result = GetAssertionResult(
            credentialId: credId,
            authenticatorData: assertion.authenticatorData,
            signature: assertion.signature,
            userHandle: userHandle,
            selectedCredential: SelectedCredential(cipher: CipherView(fido2CredentialNewView: fido2NewView, timeProvider: CurrentTime()), credential: fido2View),
        )
        return (result, assertion.prfResult)
    }



    // MARK: PRIVATE
    private func assertWebAuthnCredential(
        withKey privKey: P256.Signing.PrivateKey,
        rpId: String,
        clientDataHash: Data,
        prfSeed: SymmetricKey,
        prfInput: Data
    ) throws -> (authenticatorData: Data, signature: Data, prfResult: Data) {
        // authenticatorData
        let authData = buildAuthenticatorData(rpId: rpId, attestedCredentialData: nil)

        // signature
        let response = try createAttestationObject(
            withKey: privKey,
            authenticatorData: authData,
            clientDataHash: clientDataHash)

        let prfResult = generatePrf(using: prfInput, from: prfSeed)
        return (authData, response.signature, prfResult)
    }

    private func buildAuthenticatorData(rpId: String, attestedCredentialData: Data?) -> Data {
        let rpIdHash = Data(SHA256.hash(data: rpId.data(using: .utf8)!))
        let signCount = UInt32(0)
        if let credential = attestedCredentialData {
            // Attesting/creating credential
            let flags = 0b01000101 // AT, UV, UP
            return rpIdHash + UInt8(flags).bytes + signCount.bytes + credential
        }
        else {
            // Asserting credential
            let flags = 0b0001_1101 // UV, UP; BE and BS also set because macOS requires it on assertions :(
            return rpIdHash + UInt8(flags).bytes + signCount.bytes
        }
    }

    private func createAttestationObject(
        withKey privKey: P256.Signing.PrivateKey,
        authenticatorData authData: Data,
        clientDataHash: Data
    ) throws -> (attestationObject: Data, signature: Data) {
        // signature
        let payload = authData + clientDataHash
        // let privKey = try P256.Signing.PrivateKey(rawRepresentation: Data(base64Encoded: record.privKey)!)
        let sig = try privKey.signature(for: payload).derRepresentation

        // attestation object
        var attObj = Data()
        attObj.append(contentsOf: [
            0xA3, // map, length 3
              0x63, 0x66, 0x6d, 0x74, // string, len 3 "fmt"
                0x66, 0x70, 0x61, 0x63, 0x6b, 0x65, 0x64, // string, len 6, "packed"
              0x67, 0x61, 0x74, 0x74, 0x53, 0x74, 0x6d, 0x74, // string, len 7, "attStmt"
                0xA2, // map, length 2
                  0x63, 0x61, 0x6c, 0x67, // string, len 3, "alg"
                    0x26, // -7 (P256)
                  0x63, 0x73, 0x69, 0x67, // string, len 3, "sig"
                  0x58, // bytes, length specified in following byte
        ])
        attObj.append(contentsOf: UInt8(sig.count).bytes)
        attObj.append(contentsOf: sig)
        attObj.append(contentsOf:[
              0x68, 0x61, 0x75, 0x74, 0x68, 0x44, 0x61, 0x74, 0x61, // string, len 8, "authData"
                0x58, // bytes, length specified in following byte.
        ])
        attObj.append(contentsOf: UInt8(authData.count).bytes)
        attObj.append(contentsOf: authData)
        return (attObj, sig)
    }

    private func generatePrf(using prfInput: Data, from seed: SymmetricKey) -> Data {
        let saltPrefix = "WebAuthn PRF\0".data(using: .utf8)!
        let salt1 = saltPrefix + prfInput
        let logger = Logger()
        seed.withUnsafeBytes{
            let seedBytes = Data(Array($0))
            logger.debug("PRF Input: \(salt1.base64EncodedString())\nPRF Seed: \(seedBytes.base64UrlEncodedString())")
        }
        // CTAP2 uses HMAC to expand salt into a PRF, so we're doing the same.
        return Data(HMAC<SHA256>.authenticationCode(for: salt1, using: seed))
    }

    private func getSecureRandomBytes(count: Int) throws -> Data {
        var bytes = [UInt8](repeating: 0, count: count)
        let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        guard status == errSecSuccess else {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(status))
        }
       return Data(bytes)
    }
}

