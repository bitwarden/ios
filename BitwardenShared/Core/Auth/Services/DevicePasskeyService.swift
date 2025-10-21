import CryptoKit
import Foundation
import ObjectiveC
import os.log
import UIKit

import BitwardenSdk
import BitwardenKit
import AuthenticationServices

protocol DevicePasskeyService {
    /// Create device passkey with PRF encryption key.
    ///
    /// Before calling, vault must be unlocked to wrap user encryption key.
    ///  - Parameters:
    ///      - masterPasswordHash: Master password hash suitable for server authentication
    func createDevicePasskey(masterPasswordHash: String, overwrite: Bool) async throws -> DevicePasskeyRecord
}

struct DefaultDevicePasskeyService : DevicePasskeyService {
    static private let decoder = JSONDecoder()
    static private let encoder = JSONEncoder()
    
    private let authAPIService: AuthAPIService
    private let clientService: ClientService
    private let environmentService: EnvironmentService
    private let keychainRepository: KeychainRepository
    private let stateService: StateService
    
    /// This is the AAGUID for the Bitwarden Passkey provider (d548826e-79b4-db40-a3d8-11116f7e8349)
    /// It is used for the Relaying Parties to identify the authenticator during registration
    private let aaguid = Data([
        0xd5, 0x48, 0x82, 0x6e, 0x79, 0xb4, 0xdb, 0x40, 0xa3, 0xd8, 0x11, 0x11, 0x6f, 0x7e, 0x83, 0x49,
    ]);
    
    /// Default PRF salt input to use if none is received from WebAuthn client.
    private let defaultLoginWithPrfSalt = Data(SHA256.hash(data: "passwordless-login".data(using: .utf8)!))
    
    init(
        authAPIService: AuthAPIService,
        clientService: ClientService,
        environmentService: EnvironmentService,
        keychainRepository: KeychainRepository,
        stateService: StateService
    ) {
        self.authAPIService = authAPIService
        self.clientService = clientService
        self.environmentService = environmentService
        self.keychainRepository = keychainRepository
        self.stateService = stateService
    }
    
    /// Create device passkey with PRF encryption key.
    ///
    /// Before calling, vault must be unlocked to wrap user encryption key.
    func createDevicePasskey(masterPasswordHash: String, overwrite: Bool) async throws -> DevicePasskeyRecord {
        if !overwrite {
            let record = try? await getRecordFromKeychain()
            guard record == nil else {
                return record!
            }
        }
        let userId = try await stateService.getActiveAccountId()
        // TODO: SUPER HACK; co-opting device key from TDE for this purpose is no good. This should not be merged.
        let deviceKey: SymmetricKey
        if let deviceKeyB64 = try? await keychainRepository.getDeviceKey(userId: userId) {
            deviceKey = SymmetricKey(data: Data(base64Encoded: deviceKeyB64)!)
        }
        else {
            deviceKey = SymmetricKey(size: SymmetricKeySize(bitCount: 512))
            let key = deviceKey.withUnsafeBytes {
                Data(Array($0)).base64EncodedString()
            }
            try await keychainRepository.setDeviceKey(key, userId: userId)
        }
        Logger.application.debug("Device key: \(deviceKey.withUnsafeBytes { Data(Array($0)).base64EncodedString() })")
        let response = try await authAPIService.getCredentialCreationOptions(SecretVerificationRequestModel(passwordHash: masterPasswordHash))
        let options = response.options
        let token = response.token
        
        
        let excludeCredentials: [PublicKeyCredentialDescriptor]? = if options.excludeCredentials != nil {
            // TODO: return early if exclude credentials matches
            try options.excludeCredentials!.map {
                return try PublicKeyCredentialDescriptor(ty: $0.type, id: Data(base64UrlEncoded: $0.id)!, transports: nil)
            }
        }
        else { nil }
        let credParams = options.pubKeyCredParams.map {
            PublicKeyCredentialParameters(ty: $0.type, alg: Int64($0.alg))
        }
        
        let origin = deriveWebOrigin()
        let clientDataJson = #"{"type":"webauthn.create","challenge":"\#(options.challenge)","origin":"\#(origin)"}"#
        let clientDataHash = Data(SHA256.hash(data: clientDataJson.data(using: .utf8)!))
        
        let credentialStore = DevicePasskeyCredentialStore(
            clientService: clientService,
            keychainRepository: keychainRepository,
            userId: userId
        )
        let userInterface = DevicePasskeyUserInterface()
        let authenticator = try await clientService
            .platform()
            .fido2()
            .deviceAuthenticator(userInterface: userInterface, credentialStore: credentialStore, deviceKey: deviceKey)
        let credRequest = MakeCredentialRequest(
            clientDataHash: clientDataHash,
            rp: PublicKeyCredentialRpEntity(id: options.rp.id, name: options.rp.name),
            user: PublicKeyCredentialUserEntity(
                id: try Data(base64UrlEncoded: options.user.id)!,
                displayName: options.user.name,
                name: options.user.name
            ),
            pubKeyCredParams: credParams,
            excludeList: excludeCredentials,
            options: Options(
                rk: true,
                uv: .required
            ),
            extensions: MakeCredentialExtensionsInput(
                prf: MakeCredentialPrfInput(
                    eval: PrfValues(first: defaultLoginWithPrfSalt, second: nil),
                )
            ),
        )
        let createdCredential = try await authenticator.makeCredential(request: credRequest)
        // at this point, there should be a device passkey in the store, with an unencrypted PRF seed.
        let record = try await getRecordFromKeychain()!

        // Create unlock keyset from PRF value
        let prfResult = createdCredential.extensions.prf!.results!.first
        let prfKeyResponse = try await clientService.crypto().makePrfUserKeySet(prf: prfResult.base64EncodedString())
        
        // Register the credential keyset with the server.
        // TODO: This only returns generic names like `iPhone` on real devices.
        // If there is a more specific name available (e.g., user-chosen),
        // that would be helpful to disambiguate in the menu.
        let clientName = await "Bitwarden App on \(UIKit.UIDevice.current.name)"
        let request = WebAuthnLoginSaveCredentialRequestModel(
            deviceResponse: WebAuthnLoginAttestationResponseRequest(
                id: createdCredential.credentialId.base64UrlEncodedString(trimPadding: false),
                rawId: createdCredential.credentialId.base64UrlEncodedString(trimPadding: false),
                type: "public-key",
                response: WebAuthnLoginAttestationResponseRequestInner(
                    attestationObject: createdCredential.attestationObject.base64UrlEncodedString(trimPadding: false),
                    clientDataJson: clientDataJson.data(using: .utf8)!.base64UrlEncodedString(trimPadding: false)
                ),
            ),
            name: clientName,
            token: token,
            supportsPrf: true,
            encryptedUserKey: prfKeyResponse.encapsulatedDownstreamKey,
            encryptedPublicKey: prfKeyResponse.encryptedEncapsulationKey,
            encryptedPrivateKey: prfKeyResponse.encryptedDecapsulationKey
        )
        try await authAPIService.saveCredential(request)
        
        return record
    }
    
    internal func getRecordFromKeychain() async throws -> DevicePasskeyRecord? {
        if let json = try? await keychainRepository.getDevicePasskey(userId: stateService.getActiveAccountId()) {
            let record: DevicePasskeyRecord = try DefaultDevicePasskeyService.decoder.decode(
                DevicePasskeyRecord.self,
                from: json.data(
                    using: .utf8
                )!
            )
            Logger.application.debug("Record: \(json) })")
            return record
        }
        else { return nil }
    }
    
    private func deriveWebOrigin() -> String {
        // TODO: Should we be using the web vault as the origin, and is this the best way to get it?
        let url = environmentService.webVaultURL
        return "\(url.scheme ?? "http")://\(url.hostWithPort!)"
    }
}

// MARK: DevicePasskeyRecord

struct DevicePasskeyRecord: Decodable, Encodable {
    let cipherId: String
    let cipherName: String
    let credentialId: String
    let deviceBound: Bool
    let keyType: String
    let keyAlgorithm: String
    let keyCurve: String
    let keyValue: String
    let rpId: String
    let rpName: String?
    let userId: String?
    let userName: String?
    let userDisplayName: String?
    let counter: String
    let discoverable: String
    let hmacSecret: String?
    let creationDate: DateTime
    
    func toCipherView() -> CipherView {
        CipherView(
            id: self.cipherId,
            organizationId: nil,
            deviceBound: true,
            folderId: nil,
            collectionIds: [],
            key: nil,
            name: self.cipherName,
            notes: nil,
            type: .login,
            login: BitwardenSdk.LoginView(
                username: nil,
                password: nil,
                passwordRevisionDate: nil,
                uris: nil,
                totp: nil,
                autofillOnPageLoad: true,
                fido2Credentials: [Fido2Credential(
                    credentialId: self.credentialId,
                    keyType: self.keyType,
                    keyAlgorithm: self.keyAlgorithm,
                    keyCurve: self.keyCurve,
                    keyValue: self.keyValue,
                    rpId: self.rpId,
                    userHandle: self.userId,
                    userName: self.userName,
                    counter: self.counter,
                    rpName: self.rpName,
                    userDisplayName: self.userDisplayName,
                    discoverable: self.discoverable,
                    hmacSecret: self.hmacSecret,
                    creationDate: self.creationDate,
                )]
            ),
            identity: nil,
            card: nil,
            secureNote: nil,
            sshKey: nil,
            favorite: false,
            reprompt: .none,
            organizationUseTotp: false,
            edit: false,
            permissions: nil,
            viewPassword: false,
            localData: nil,
            attachments: nil,
            fields: nil,
            passwordHistory: nil,
            creationDate: self.creationDate,
            deletedDate: nil,
            revisionDate: self.creationDate,
            archivedDate: nil
        )
    }
        func toCipher() -> Cipher {
            Cipher(
                id: self.cipherId,
                organizationId: nil,
                deviceBound: true,
                folderId: nil,
                collectionIds: [],
                key: nil,
                name: self.cipherName,
                notes: nil,
                type: .login,
                login: BitwardenSdk.Login(
                    username: nil,
                    password: nil,
                    passwordRevisionDate: nil,
                    uris: nil,
                    totp: nil,
                    autofillOnPageLoad: true,
                    fido2Credentials: [Fido2Credential(
                        credentialId: self.credentialId,
                        keyType: self.keyType,
                        keyAlgorithm: self.keyAlgorithm,
                        keyCurve: self.keyCurve,
                        keyValue: self.keyValue,
                        rpId: self.rpId,
                        userHandle: self.userId,
                        userName: self.userName,
                        counter: self.counter,
                        rpName: self.rpName,
                        userDisplayName: self.userDisplayName,
                        discoverable: self.discoverable,
                        hmacSecret: self.hmacSecret,
                        creationDate: self.creationDate,
                    )]
                ),
                identity: nil,
                card: nil,
                secureNote: nil,
                sshKey: nil,
                favorite: false,
                reprompt: .none,
                organizationUseTotp: false,
                edit: false,
                permissions: nil,
                viewPassword: false,
                localData: nil,
                attachments: nil,
                fields: nil,
                passwordHistory: nil,
                creationDate: self.creationDate,
                deletedDate: nil,
                revisionDate: self.creationDate,
                archivedDate: nil
            )
    }
}

// MARK: DevicePasskeyCredentialStore

final class DevicePasskeyCredentialStore : Fido2CredentialStore {
    let clientService: ClientService
    let keychainRepository: KeychainRepository
    let userId: String
    
    init(clientService: ClientService, keychainRepository: KeychainRepository, userId: String) {
        self.clientService = clientService
        self.keychainRepository = keychainRepository
        self.userId = userId
    }
    
    func findCredentials(ids: [Data]?, ripId: String) async throws -> [BitwardenSdk.CipherView] {
        // TODO: Decrypt values before returning to authenticator
        guard let record = try? await getDevicePasskey() else {
            return []
        }
        // record contains encrypted values; we need to decrypt them
        let encryptedCipher = record.toCipher()
        let cipherView = try await clientService.vault().ciphers().decrypt(cipher: encryptedCipher)
        
        let deviceKey = try await SymmetricKey(data: Data(base64Encoded: keychainRepository.getDeviceKey(userId: userId)!)!)
        let fido2CredentialAutofillViews = try await clientService.platform()
            .fido2()
            .decryptFido2AutofillCredentials(cipherView: cipherView, encryptionKey: deviceKey)

        guard let fido2CredentialAutofillView = fido2CredentialAutofillViews[safeIndex: 0],
              ripId == fido2CredentialAutofillView.rpId else {
            return []
        }

        if let ids,
           !ids.contains(fido2CredentialAutofillView.credentialId) {
            return []
        }

        return [cipherView]
    }
    
    func allCredentials() async throws -> [BitwardenSdk.CipherListView] {
        // TODO: Decrypt values before returning to authenticator
        var results: [BitwardenSdk.CipherListView] = []
        if let record = try? await getDevicePasskey() {
            // record contains encrypted values; we need to decrypt them
            let encryptedCipherView = record.toCipherView()
            let deviceKey = try await Data(base64Encoded: keychainRepository.getDeviceKey(userId: userId)!)!
            let decrypted = try await clientService.vault().ciphers().decryptFido2Credentials(cipherView: encryptedCipherView, encryptionKey: deviceKey)[0]
            
            let fido2View = Fido2CredentialListView(
                credentialId: decrypted.credentialId,
                rpId: decrypted.rpId,
                userHandle: decrypted.userHandle,
                userName: decrypted.userName,
                userDisplayName: decrypted.userDisplayName,
                counter: decrypted.counter,
            )
            let loginView = BitwardenSdk.LoginListView(
                fido2Credentials: [fido2View],
                hasFido2: true,
                username: decrypted.userDisplayName,
                totp: nil,
                uris: nil,
            )

            let cipherView = CipherListView(
                id: record.cipherId,
                organizationId: nil,
                folderId: nil,
                collectionIds: [],
                key: nil, // setting the key to null means that it will be encrypted by the user key directly.
                name: record.cipherName,
                subtitle: "Vault Passkey created by Bitwarden app",
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
        // TODO: this is encrypted by the user encryption key, which will be decrypted on findCredentials, I think?
        // I'm not sure if we want this to be bound to the user key, which would mean it would break when the user key is rotated.
        // go ahead and try it for now.
        if let fido2cred = cred.cipher.login?.fido2Credentials?[safeIndex: 0] {
            let record = DevicePasskeyRecord(
                cipherId: UUID().uuidString,
                cipherName: cred.cipher.name,
                credentialId: fido2cred.credentialId,
                deviceBound: cred.cipher.deviceBound,
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
                hmacSecret: fido2cred.hmacSecret,
                creationDate: cred.cipher.creationDate
            )
            let recordJson = try String(data: JSONEncoder().encode(record), encoding: .utf8)!
            try await keychainRepository.setDevicePasskey(recordJson, userId: cred.encryptedFor)
        }
    }
    
    private func getDevicePasskey() async throws -> DevicePasskeyRecord? {
        if let json = try? await keychainRepository.getDevicePasskey(
            userId: userId
        ){
            return try? JSONDecoder()
                .decode(
                    DevicePasskeyRecord.self,
                    from: json
                        .data(
                    using: .utf8
                )!
            )
        } else { return nil }
    }
}

final class DevicePasskeyUserInterface: Fido2UserInterface {
    func checkUser(options: BitwardenSdk.CheckUserOptions, hint: BitwardenSdk.UiHint) async throws -> BitwardenSdk.CheckUserResult {
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
    
    func isVerificationEnabled() async -> Bool {
        true
    }
}

@available(iOS 18.0, *)
extension GetAssertionExtensionsInput {
    init(passkeyExtensionInput: ASPasskeyAssertionCredentialExtensionInput) {
        var eval: PrfValues?
        if let credValue = passkeyExtensionInput.prf?.inputValues {
            eval = PrfValues(first: credValue.saltInput1, second: credValue.saltInput2)
        }
        
        let evalByCredential = passkeyExtensionInput.prf?.perCredentialInputValues?.mapValues { credValue -> PrfValues in
            PrfValues(first: credValue.saltInput1, second: credValue.saltInput2)
        }
        
        let prfInput = GetAssertionPrfInput(
            eval: eval,
            evalByCredential: evalByCredential
        )
        self.init(prf: prfInput)
    }
}

@available(iOS 18.0, *)
extension MakeCredentialExtensionsInput {
    init(passkeyExtensionInput: ASPasskeyRegistrationCredentialExtensionInput) {
        var eval: PrfValues?
        if let credValue = passkeyExtensionInput.prf?.inputValues {
            eval = PrfValues(first: credValue.saltInput1, second: credValue.saltInput2)
        }
        
        let prfInput = MakeCredentialPrfInput(eval: eval)
        self.init(prf: prfInput)
    }
}

@available(iOS 18.0, *)
extension GetAssertionExtensionsOutput {
    func toNative() -> ASPasskeyAssertionCredentialExtensionOutput? {
        let largeBlob: ASAuthorizationPublicKeyCredentialLargeBlobAssertionOutput? = nil
        var prf: ASAuthorizationPublicKeyCredentialPRFAssertionOutput?
        if let prfResults = self.prf?.results {
            let second: SymmetricKey? = if let second = prfResults.second {
                SymmetricKey(data: second)
            } else { nil }
            prf = ASAuthorizationPublicKeyCredentialPRFAssertionOutput(
                first: SymmetricKey(data: prfResults.first),
                second: second
            )
        }
        let extOutput: ASPasskeyAssertionCredentialExtensionOutput? = if largeBlob != nil || prf != nil {
            ASPasskeyAssertionCredentialExtensionOutput(largeBlob: largeBlob, prf: prf)
        } else { nil }
        return extOutput
    }
}

@available(iOS 18.0, *)
extension MakeCredentialExtensionsOutput {
    func toNative() -> ASPasskeyRegistrationCredentialExtensionOutput? {
        let largeBlob: ASAuthorizationPublicKeyCredentialLargeBlobRegistrationOutput? = nil
        var prf: ASAuthorizationPublicKeyCredentialPRFRegistrationOutput?
        if let prfResults = self.prf?.results {
            let second: SymmetricKey? = if let second = prfResults.second {
                SymmetricKey(data: second)
            } else { nil }
            prf = ASAuthorizationPublicKeyCredentialPRFRegistrationOutput(
                first: SymmetricKey(data: prfResults.first),
                second: second
            )
        }
        let extOutput: ASPasskeyRegistrationCredentialExtensionOutput? = if largeBlob != nil || prf != nil {
            ASPasskeyRegistrationCredentialExtensionOutput(largeBlob: largeBlob, prf: prf)
        } else { nil }
        return extOutput
    }
}
