import CryptoKit
import Foundation

// MARK: - PasskeyAssertionVerifier

/// Verifies a WebAuthn passkey assertion against a previously stored registration: matches the
/// credential ID, checks the relying party hash and user-presence flag embedded in `authData`,
/// checks the client data's type and challenge, and verifies the ECDSA signature using the stored
/// credential's public key.
///
enum PasskeyAssertionVerifier {
    // MARK: Types

    /// Errors that can occur while verifying a passkey assertion.
    enum VerificationError: Error, Equatable, LocalizedError {
        /// No stored credential matched the assertion's credential ID.
        case credentialNotFound

        /// The authenticator data was too short to contain the expected fields.
        case authDataTooShort

        /// The authenticator data's relying party ID hash did not match the expected relying party.
        case rpIdHashMismatch

        /// The authenticator data's flags did not have the "user present" bit set.
        case userPresenceNotAsserted

        /// The client data's `type` was not `"webauthn.get"`.
        case unexpectedClientDataType(String)

        /// The challenge in the client data did not match the challenge sent to the authenticator.
        case challengeMismatch

        /// The assertion signature did not verify against the stored credential's public key.
        case signatureInvalid

        var errorDescription: String? {
            switch self {
            case .credentialNotFound:
                Localizations.credentialNotFoundReceived
            case .authDataTooShort:
                Localizations.authDataTooShortReceived
            case .rpIdHashMismatch:
                Localizations.rpIdHashMismatchReceived
            case .userPresenceNotAsserted:
                Localizations.userPresenceNotAssertedReceived
            case let .unexpectedClientDataType(type):
                Localizations.unexpectedAssertionClientDataTypeReceived(type)
            case .challengeMismatch:
                Localizations.challengeMismatchReceived
            case .signatureInvalid:
                Localizations.signatureInvalidReceived
            }
        }
    }

    /// The raw fields of a WebAuthn assertion response, as returned by the authenticator.
    struct RawAssertion {
        /// The credential ID returned by the authenticator.
        var credentialId: Data

        /// The raw `authenticatorData` returned by the authenticator.
        var rawAuthenticatorData: Data

        /// The raw ECDSA signature (ASN.1 DER) returned by the authenticator.
        var signature: Data

        /// The raw `clientDataJSON` returned by the authenticator.
        var rawClientDataJSON: Data
    }

    // MARK: Methods

    /// Verifies a passkey assertion against a list of candidate stored credentials.
    ///
    /// - Parameters:
    ///   - rpId: The relying party identifier the assertion was requested for.
    ///   - assertion: The raw assertion fields returned by the authenticator.
    ///   - expectedChallenge: The challenge that was sent with the assertion request.
    ///   - candidates: The previously stored credentials to match against.
    /// - Returns: The stored credential the assertion was verified against.
    ///
    static func verify(
        rpId: String,
        assertion: RawAssertion,
        expectedChallenge: Data,
        candidates: [StoredPasskeyCredential],
    ) throws -> StoredPasskeyCredential {
        guard let credential = candidates.first(where: { $0.credentialId == assertion.credentialId }) else {
            throw VerificationError.credentialNotFound
        }

        let authDataBytes = [UInt8](assertion.rawAuthenticatorData)
        guard authDataBytes.count >= 37 else { throw VerificationError.authDataTooShort }

        let rpIdHash = Data(SHA256.hash(data: Data(rpId.utf8)))
        guard rpIdHash == Data(authDataBytes[0 ..< 32]) else { throw VerificationError.rpIdHashMismatch }

        let flags = authDataBytes[32]
        guard flags & 0x01 != 0 else { throw VerificationError.userPresenceNotAsserted }

        let clientData = try ClientDataJSONParser.parse(fromClientDataJSON: assertion.rawClientDataJSON)
        guard clientData.type == "webauthn.get" else {
            throw VerificationError.unexpectedClientDataType(clientData.type)
        }
        guard clientData.challenge == expectedChallenge else {
            throw VerificationError.challengeMismatch
        }

        let clientDataHash = Data(SHA256.hash(data: assertion.rawClientDataJSON))
        let signedData = assertion.rawAuthenticatorData + clientDataHash

        guard let publicKey = try? P256.Signing.PublicKey(x963Representation: credential.publicKeyX963),
              let ecdsaSignature = try? P256.Signing.ECDSASignature(derRepresentation: assertion.signature),
              publicKey.isValidSignature(ecdsaSignature, for: signedData)
        else {
            throw VerificationError.signatureInvalid
        }

        return credential
    }
}
