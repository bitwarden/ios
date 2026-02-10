// MARK: - DeviceAuthKeyAuthenticator

import os.log
import BitwardenSdk
import BitwardenKit
import CryptoKit
import Foundation

// TODO(PM-26177): This is a temporary implementation for the device authenticator that will eventually move to the SDK.
class DeviceAuthKeyAuthenticator {
    /// This is the AAGUID for the Bitwarden Passkey provider (d548826e-79b4-db40-a3d8-11116f7e8349)
    /// It is used for the Relaying Parties to identify the authenticator during registration
    private let aaguid = Data([
        0xd5, 0x48, 0x82, 0x6e, 0x79, 0xb4, 0xdb, 0x40, 0xa3, 0xd8, 0x11, 0x11, 0x6f, 0x7e, 0x83, 0x49,
    ]);

    /// Default PRF salt input to use if none is received from WebAuthn client.
    private let defaultLoginWithPrfSalt = Data(SHA256.hash(data: "passwordless-login".data(using: .utf8)!))

    private let deviceAuthKeychainRepository: DeviceAuthKeychainRepository
    private let userId: String

    init(deviceAuthKeychainRepository: DeviceAuthKeychainRepository, userId: String) {
        self.deviceAuthKeychainRepository = deviceAuthKeychainRepository
        self.userId = userId
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
              let prfInput = try? Data(base64urlEncoded: prfInputB64) else {
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
            counter: "0",
            creationDate: Date(),
            credentialId: result.credentialId.base64EncodedString(),
            discoverable: "true",
            hmacSecret: prfSeedB64,
            keyAlgorithm: "-7",
            keyCurve: "P-256",
            keyType: "public-key",
            keyValue: privKey.rawRepresentation.base64EncodedString(),
            rpId: request.rp.id,
            rpName: request.rp.name ?? request.rp.id,
            userDisplayName: request.user.displayName,
            userId: request.user.id.base64EncodedString(),
            userName: request.user.name,
        )
        let metadata = DeviceAuthKeyMetadata(
            cipherId: record.cipherId,
            credentialId: result.credentialId,
            rpId: record.rpId,
            userHandle: request.user.id,
            userName: request.user.name,
        )
        try await deviceAuthKeychainRepository.setDeviceAuthKey(record: record, metadata: metadata, userId: userId)
        return (result, prfResult)
    }

    /// Use device auth key to assert a credential, outputting PRF output.
    func getAssertion(request: GetAssertionRequest) async throws -> (GetAssertionResult, Data?)? {
        guard let record = try await deviceAuthKeychainRepository.getDeviceAuthKey(userId: userId) else {
            throw DeviceAuthKeyError.missingOrInvalidKey
        }

        // extensions
        // prf
        let prfInput = if let extJson = request.extensions,
           let extJsonData = extJson.data(using: .utf8),
           let extInputs = try? JSONDecoder.defaultDecoder.decode(WebAuthnAuthenticationExtensionsClientInputs.self, from: extJsonData),
           let prfEval = extInputs.prf?.eval,
           let prfInput = try Data(base64urlEncoded: prfEval.first)
        {
            prfInput
        } else {
            defaultLoginWithPrfSalt
        }

        guard let prfSeedData = Data(base64Encoded: record.hmacSecret) else {
            throw DeviceAuthKeyError.missingOrInvalidKey
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
            logger.debug("PRF Input: \(salt1.base64urlEncodedString())\nPRF Seed: \(seedBytes.base64urlEncodedString())")
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
