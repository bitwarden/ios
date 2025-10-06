//
//  DevicePasskeyService.swift
//  Bitwarden
//
//  Created by Isaiah Inuwa on 2025-10-03.
//


import CryptoKit
import Foundation
import ObjectiveC
import os.log
import UIKit

import BitwardenSdk
import BitwardenKit

protocol DevicePasskeyService {
    /// Create device passkey with PRF encryption key.
    ///
    /// Before calling, vault must be unlocked to wrap user encryption key.
    ///  - Parameters:
    ///      - masterPasswordHash: Master password hash suitable for server authentication
    func createDevicePasskey(masterPasswordHash: String, overwrite: Bool) async throws -> DevicePasskeyRecord
    
    /// Retrieve device passkey record
    func getDevicePasskey() async throws -> DevicePasskeyRecord?
    
    func getPrfResult() async throws -> SymmetricKey
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
            if let json = try? await keychainRepository.getDevicePasskey(userId: stateService.getActiveAccountId()) {
                let record: DevicePasskeyRecord = try DefaultDevicePasskeyService.decoder.decode(
                    DevicePasskeyRecord.self,
                    from: json.data(
                        using: .utf8
                    )!
                )
                return record
            }
        }
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
        
        let userId = try await stateService.getActiveAccountId()
        let credentialStore = DevicePasskeyCredentialStore(
            clientService: clientService,
            keychainRepository: keychainRepository,
            userId: userId
        )
        let userInterface = DevicePasskeyUserInterface()
        let authenticator = try await clientService
            .platform()
            .fido2()
            .authenticator(userInterface: userInterface, credentialStore: credentialStore)
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
            extensions: nil,
        )
        let createdCredential = try await authenticator.makeCredential(request: credRequest)
        // at this point, there should be a device passkey in the store, with an unencrypted PRF seed.
        let record = try await getRecordFromKeychain()!

        let prfSeed = SymmetricKey(data: Data(base64Encoded: record.prfSeed)!)
        let prfResult = generatePrf(using: defaultLoginWithPrfSalt, from: prfSeed)
        let prfKeyResponse = try await clientService.crypto().makePrfUserKeySet(prf: prfResult.base64EncodedString())
        
        // let (createdCredential, privKey) = try makeWebAuthnCredential(rpId: options.rp.id, clientDataHash: clientDataHash)
        // Register the credential keyset with the server.
        // TODO: This only returns generic names like `iPhone`.
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
            return record
        }
        else { return nil }
    }
    
    private func makeWebAuthnCredential(
        rpId: String,
        clientDataHash: Data
    ) throws -> (
        credential: MakeCredentialResult,
        privKey: P256.Signing.PrivateKey
    ) {
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
            let attestedCredentialData = aaguid + UInt16(credId.count).bytes + credId + cosePubKey
            
            // authenticatorData
            let authData = buildAuthenticatorData(rpId: rpId, attestedCredentialData: attestedCredentialData)
            
            // signature
            let response = try createAttestationObject(
                withKey: privKey,
                authenticatorData: authData,
                clientDataHash: clientDataHash)
            let result = MakeCredentialResult(
                authenticatorData: authData,
                attestationObject: response.attestationObject,
                credentialId: credId)
            return (credential: result, privKey: privKey)
        }
    
    private func generatePrf(using prfInput: Data, from seed: SymmetricKey) -> Data {
        let saltPrefix = "WebAuthn PRF\0".data(using: .utf8)!
        let salt1 = saltPrefix + prfInput
        let logger = Logger()
        seed.withUnsafeBytes{
            let seedBytes = Data(Array($0))
            logger.debug("PRF Input: \(salt1.base64EncodedString(), privacy: .public)\nPRF Seed: \(seedBytes.base64EncodedString(), privacy: .public)")
        }
        // CTAP2 uses HMAC to expand salt into a PRF, so we're doing the same.
        return Data(HMAC<SHA256>.authenticationCode(for: salt1, using: seed))
    }
    
    func getDevicePasskey() async throws -> DevicePasskeyRecord? {
        guard let json = try await keychainRepository.getDevicePasskey(userId: stateService.getActiveAccountId()) else { return nil }
        let record: DevicePasskeyRecord = try DefaultDevicePasskeyService.decoder.decode(
            DevicePasskeyRecord.self,
            from: json.data(
                using: .utf8
            )!
        )
        return record
    }
    
    func getPrfResult() async throws -> SymmetricKey {
        let record = try await getDevicePasskey()!
        let prfSeed = SymmetricKey(data: Data(base64Encoded: record.prfSeed)!)
        return SymmetricKey(data: generatePrf(using: defaultLoginWithPrfSalt, from: prfSeed))
    }
    
    private func deriveWebOrigin() -> String {
        // TODO: Should we be using the web vault as the origin, and is this the best way to get it?
        let url = environmentService.webVaultURL
        return "\(url.scheme ?? "http")://\(url.hostWithPort!)"
    }
    
    private func getSecureRandomBytes(count: Int) throws -> Data {
        var bytes = [UInt8](repeating: 0, count: count)
        let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        guard status == errSecSuccess else {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(status))
        }
        return Data(bytes)
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
}

// MARK: DevicePasskeyRecord

struct DevicePasskeyRecord: Decodable, Encodable {
    let cipherId: String
    let cipherName: String
    let credentialId: String
    let keyType: String
    let keyAlgorithm: String
    let keyCurve: String
    let keyValue: String
    let prfSeed: String
    let rpId: String
    let rpName: String?
    let userId: String?
    let userName: String?
    let userDisplayName: String?
    let counter: String
    let discoverable: String
    let creationDate: DateTime
    
    func toCipherView() -> CipherView {
        CipherView(
            id: self.cipherId,
            organizationId: nil,
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
        
        let fido2CredentialAutofillViews = try await clientService.platform()
            .fido2()
            .decryptFido2AutofillCredentials(cipherView: cipherView)

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
            let decrypted = try await clientService.vault().ciphers().decryptFido2Credentials(cipherView: encryptedCipherView)[0]
            
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
        // this is encrypted by the user encryption key, which will be decrypted on findCredentials, I think?
        // I'm not sure if we want this to be bound to the user key, which would mean it would break when the user key is rotated.
        // go ahead and try it for now.
        if let fido2cred = cred.cipher.login?.fido2Credentials?[safeIndex: 0] {
            // TODO: prf value needs to be moved to FIDO credential model. Making it up for now.
            let prfSeed = SymmetricKey(size: SymmetricKeySize(bitCount: 256)).withUnsafeBytes {
                Data(Array($0)).base64EncodedString()
            }
            let record = DevicePasskeyRecord(
                cipherId: UUID().uuidString,
                cipherName: cred.cipher.name,
                credentialId: fido2cred.credentialId,
                keyType: fido2cred.keyType,
                keyAlgorithm: fido2cred.keyAlgorithm,
                keyCurve: fido2cred.keyCurve,
                keyValue: fido2cred.keyValue,
                prfSeed: prfSeed,
                rpId: fido2cred.rpId,
                rpName: fido2cred.rpName,
                userId: fido2cred.userHandle,
                userName: fido2cred.userName,
                userDisplayName: fido2cred.userDisplayName,
                counter: fido2cred.counter,
                discoverable: fido2cred.discoverable,
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

final class DevicePasskeyUserInterface : Fido2UserInterface {
    func checkUser(options: BitwardenSdk.CheckUserOptions, hint: BitwardenSdk.UiHint) async throws -> BitwardenSdk.CheckUserResult {
        BitwardenSdk.CheckUserResult(userPresent: true, userVerified: true)
    }
    
    func pickCredentialForAuthentication(availableCredentials: [BitwardenSdk.CipherView]) async throws -> BitwardenSdk.CipherViewWrapper {
        BitwardenSdk.CipherViewWrapper(cipher: availableCredentials[0])
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

private extension Cipher {
    /// Whether the cipher is active, is a login and has Fido2 credentials.
    var isActiveWithFido2Credentials: Bool {
        deletedDate == nil
            && type == .login
            && login?.fido2Credentials?.isEmpty == false
    }
}
