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
    func createDevicePasskey(masterPasswordHash: String) async throws
    
    /// Use device passkey to assert a credential, outputting PRF output.
    func useDevicePasskey(for request: GetAssertionRequest) async throws -> (GetAssertionResult, Data?)?
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
    func createDevicePasskey(masterPasswordHash: String) async throws {
        let response = try await authAPIService.getCredentialCreationOptions(SecretVerificationRequestModel(passwordHash: masterPasswordHash))
        let options = response.options
        let token = response.token
        
        let (prfInput, _) = try getPrfInput(extensionsInput: response.options.extensions)
        
        let excludeCredentials: [PublicKeyCredentialDescriptor]? = if options.excludeCredentials != nil {
            // TODO: return early if exclude credentials matches
            options.excludeCredentials!.map {
                return PublicKeyCredentialDescriptor(ty: $0.type, id: Data(base64UrlEncoded: $0.id)!, transports: nil)
            }
        }
        else { nil }
        let credParams = options.pubKeyCredParams.map {
            PublicKeyCredentialParameters(ty: $0.type, alg: Int64($0.alg))
        }
        
        let origin = deriveWebOrigin()
        let clientDataJson = #"{"type":"webauthn.create","challenge":"\#(options.challenge)","origin":"\#(origin)"}"#
        let clientDataHash = Data(SHA256.hash(data: clientDataJson.data(using: .utf8)!))
        
        let credRequest = MakeCredentialRequest(
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
            extensions: nil,
        )
        
        let makeResult = try makeWebAuthnCredential(request: credRequest, prfInput: prfInput)
        let createdCredential = makeResult.credential
        let prfKeyResponse = try await clientService.crypto().derivePrfKey(prf: makeResult.prfResult.base64EncodedString())
        
        // Store the passkey with its PRF seed
        let credRecord = DevicePasskeyRecord(
            credId: createdCredential.credentialId.base64EncodedString(),
            privKey: makeResult.privKey.rawRepresentation.base64EncodedString(),
            prfSeed: makeResult.prfSeed.withUnsafeBytes{
                Data(Array($0)).base64EncodedString()
            },
            rpId: credRequest.rp.id,
            rpName: credRequest.rp.name,
            userId: credRequest.user.id.base64EncodedString(),
            userName: credRequest.user.name,
            userDisplayName: credRequest.user.displayName,
            creationDate: CurrentTime().presentTime,
        )
        let encoder = JSONEncoder()
        let recordJson = try String(data: encoder.encode(credRecord), encoding: .utf8)!
        try await keychainRepository.setDevicePasskey(recordJson, userId: stateService.getActiveAccountId())
        
        // Register the credential keyset with the server.
        // TODO: This only returns generic names like `iPhone`.
        // If there is a more specific name available (e.g., user-chosen),
        // that would be helpful to disambiguate in the menu.
        let clientName = "Bitwarden App on \(await UIKit.UIDevice.current.name)"
        let request = WebAuthnLoginSaveCredentialRequestModel(
            deviceResponse: WebAuthnLoginAttestationResponseRequest(
                id: createdCredential.credentialId.base64UrlEncodedString(trimPadding: false),
                rawId: createdCredential.credentialId.base64UrlEncodedString(trimPadding: false),
                type: "public-key",
                response: WebAuthnLoginAttestationResponseRequestInner(
                    attestationObject: createdCredential.attestationObject.base64UrlEncodedString(trimPadding: false),
                    clientDataJson: clientDataJson.data(using: .utf8)!.base64UrlEncodedString(trimPadding: false),
                ),
            ),
            name: clientName,
            token: token,
            supportsPrf: true,
            encryptedUserKey: prfKeyResponse.encapsulatedUserKey,
            encryptedPublicKey: prfKeyResponse.encryptedEncapsulationKey,
            encryptedPrivateKey: prfKeyResponse.wrappedDecapsulationKey,
        )
        try await authAPIService.saveCredential(request)
    }
    
    /// Emulates a FIDO2 authenticator.
    private func makeWebAuthnCredential(request: MakeCredentialRequest, prfInput: Data) throws -> DevicePasskeyResult {
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
        
        // PRF
        // We're processing this as a WebAuthn extension, not a CTAP2 extension,
        // so we're not writing this to the extension data in the authenticator data.
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
        return DevicePasskeyResult(credential: result, privKey: privKey, prfSeed: prfSeed, prfResult: prfResult)
    }
    
    /// Use device passkey to assert a credential, outputting PRF output.
    func useDevicePasskey(for request: GetAssertionRequest) async throws -> (GetAssertionResult, Data?)? {
        let webVaultRpId = deriveRpId()
        guard webVaultRpId == request.rpId else { return nil }
        guard let json = try await keychainRepository.getDevicePasskey(userId: stateService.getActiveAccountId()) else {
            Logger.application.warning("Matched Bitwarden Web Vault rpID, but no device passkey found.")
            return nil
        }
        
        let record: DevicePasskeyRecord = try DefaultDevicePasskeyService.decoder.decode(DevicePasskeyRecord.self, from: json.data(using: .utf8)!)
        
        // extensions
        // prf
        let extInputs = if let extJson = request.extensions {
            try DefaultDevicePasskeyService.decoder.decode(AuthenticationExtensionsClientInputs.self, from: extJson.data(using: .utf8)!)
        } else { nil as AuthenticationExtensionsClientInputs? }
        let (prfInput, _) = try getPrfInput(extensionsInput: extInputs)
        let prfSeed = SymmetricKey(data: Data(base64Encoded: record.prfSeed)!)
        
        // TODO: this is unused, but appears in GetAssertionResult signature.
        let fido2View = Fido2CredentialView(
            credentialId: record.credId,
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
            credentialId: record.credId,
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
        let credId = Data(base64Encoded: record.credId)!
        let userHandle = Data(base64Encoded: record.userId!)!
        let privKey = try P256.Signing.PrivateKey(rawRepresentation: Data(base64Encoded: record.privKey)!)
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
    
    private func deriveRpId() -> String {
        // TODO: Should we be using the web vault as the origin, and is this the best way to get it?
        environmentService.webVaultURL.domain!
    }
    
    private func deriveWebOrigin() -> String {
        // TODO: Should we be using the web vault as the origin, and is this the best way to get it?
        let url = environmentService.webVaultURL
        return "\(url.scheme ?? "http")://\(url.hostWithPort!)"
    }
    
    private func getPrfInput(extensionsInput extInputs: AuthenticationExtensionsClientInputs?) throws -> (salt1: Data, salt2: Data?) {
        if let prfInputs = extInputs?.prf?.eval {
            let input1 = Data(base64UrlEncoded: prfInputs.first)!
            let input2: Data? = if let second = prfInputs.second {
                Data(base64UrlEncoded: second)
            } else { nil }
            return (input1, input2)
        }
        else {
            return (defaultLoginWithPrfSalt, nil)
        }
    }

    struct DevicePasskeyResult {
        let credential: MakeCredentialResult
        let privKey: P256.Signing.PrivateKey
        let prfSeed: SymmetricKey
        let prfResult: Data
    }
}

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
