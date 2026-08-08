import CryptoKit
import TestHelpers
import XCTest

@testable import TestHarnessShared

// MARK: - PasskeyAssertionVerifierTests

/// Tests for `PasskeyAssertionVerifier`.
///
class PasskeyAssertionVerifierTests: BitwardenTestCase {
    // MARK: Tests

    /// `verify` returns the matching stored credential when the signature is valid.
    func test_verify_validSignature_returnsMatchingCredential() throws {
        let fixture = try AssertionFixture.valid()

        let result = try PasskeyAssertionVerifier.verify(
            rpId: fixture.rpId,
            assertion: fixture.rawAssertion,
            expectedChallenge: fixture.challenge,
            candidates: [fixture.storedCredential],
        )

        XCTAssertEqual(result, fixture.storedCredential)
    }

    /// `verify` throws `.credentialNotFound` when no candidate matches the assertion's credential ID.
    func test_verify_noMatchingCredential_throwsCredentialNotFound() throws {
        let fixture = try AssertionFixture.valid()
        var assertion = fixture.rawAssertion
        assertion.credentialId = Data([0xFF, 0xFF])

        XCTAssertThrowsError(
            try PasskeyAssertionVerifier.verify(
                rpId: fixture.rpId,
                assertion: assertion,
                expectedChallenge: fixture.challenge,
                candidates: [fixture.storedCredential],
            ),
        ) { error in
            XCTAssertEqual(error as? PasskeyAssertionVerifier.VerificationError, .credentialNotFound)
        }
    }

    /// `verify` throws `.authDataTooShort` when `rawAuthenticatorData` is shorter than the fixed
    /// rpIdHash/flags/signCount prefix.
    func test_verify_truncatedAuthenticatorData_throwsAuthDataTooShort() throws {
        let fixture = try AssertionFixture.valid()
        var assertion = fixture.rawAssertion
        assertion.rawAuthenticatorData = fixture.rawAuthenticatorData.prefix(36)

        XCTAssertThrowsError(
            try PasskeyAssertionVerifier.verify(
                rpId: fixture.rpId,
                assertion: assertion,
                expectedChallenge: fixture.challenge,
                candidates: [fixture.storedCredential],
            ),
        ) { error in
            XCTAssertEqual(error as? PasskeyAssertionVerifier.VerificationError, .authDataTooShort)
        }
    }

    /// `verify` throws `.rpIdHashMismatch` when the relying party ID doesn't match the one the
    /// authenticator data was produced for.
    func test_verify_wrongRpId_throwsRpIdHashMismatch() throws {
        let fixture = try AssertionFixture.valid()

        XCTAssertThrowsError(
            try PasskeyAssertionVerifier.verify(
                rpId: "attacker.example",
                assertion: fixture.rawAssertion,
                expectedChallenge: fixture.challenge,
                candidates: [fixture.storedCredential],
            ),
        ) { error in
            XCTAssertEqual(error as? PasskeyAssertionVerifier.VerificationError, .rpIdHashMismatch)
        }
    }

    /// `verify` throws `.userPresenceNotAsserted` when the authenticator data's flags don't have
    /// the "user present" bit set.
    func test_verify_userPresenceFlagNotSet_throwsUserPresenceNotAsserted() throws {
        let fixture = try AssertionFixture.valid(userPresent: false)

        XCTAssertThrowsError(
            try PasskeyAssertionVerifier.verify(
                rpId: fixture.rpId,
                assertion: fixture.rawAssertion,
                expectedChallenge: fixture.challenge,
                candidates: [fixture.storedCredential],
            ),
        ) { error in
            XCTAssertEqual(error as? PasskeyAssertionVerifier.VerificationError, .userPresenceNotAsserted)
        }
    }

    /// `verify` throws `.unexpectedClientDataType` when the client data's `type` isn't `webauthn.get`.
    func test_verify_wrongClientDataType_throwsUnexpectedClientDataType() throws {
        let fixture = try AssertionFixture.valid(clientDataType: "webauthn.create")

        XCTAssertThrowsError(
            try PasskeyAssertionVerifier.verify(
                rpId: fixture.rpId,
                assertion: fixture.rawAssertion,
                expectedChallenge: fixture.challenge,
                candidates: [fixture.storedCredential],
            ),
        ) { error in
            XCTAssertEqual(
                error as? PasskeyAssertionVerifier.VerificationError,
                .unexpectedClientDataType("webauthn.create"),
            )
        }
    }

    /// `verify` throws `.challengeMismatch` when the client data's challenge doesn't match the
    /// challenge that was sent with the request.
    func test_verify_mismatchedChallenge_throwsChallengeMismatch() throws {
        let fixture = try AssertionFixture.valid()

        XCTAssertThrowsError(
            try PasskeyAssertionVerifier.verify(
                rpId: fixture.rpId,
                assertion: fixture.rawAssertion,
                expectedChallenge: Data([0x00, 0x01, 0x02]),
                candidates: [fixture.storedCredential],
            ),
        ) { error in
            XCTAssertEqual(error as? PasskeyAssertionVerifier.VerificationError, .challengeMismatch)
        }
    }

    /// `verify` throws `.signatureInvalid` when the signature was produced by a different key than
    /// the one on file for the matched credential.
    func test_verify_signatureFromDifferentKey_throwsSignatureInvalid() throws {
        let fixture = try AssertionFixture.valid()
        let otherKey = P256.Signing.PrivateKey()
        let signedData = fixture.rawAuthenticatorData + Data(SHA256.hash(data: fixture.rawClientDataJSON))
        var assertion = fixture.rawAssertion
        assertion.signature = try otherKey.signature(for: signedData).derRepresentation

        XCTAssertThrowsError(
            try PasskeyAssertionVerifier.verify(
                rpId: fixture.rpId,
                assertion: assertion,
                expectedChallenge: fixture.challenge,
                candidates: [fixture.storedCredential],
            ),
        ) { error in
            XCTAssertEqual(error as? PasskeyAssertionVerifier.VerificationError, .signatureInvalid)
        }
    }

    /// `verify` picks the candidate whose credential ID matches the assertion, when multiple
    /// candidates are present.
    func test_verify_multipleCandidates_picksMatchingCredentialId() throws {
        let fixture = try AssertionFixture.valid()
        let otherCredential = StoredPasskeyCredential(
            createdAt: Date(timeIntervalSince1970: 0),
            credentialId: Data([0xAA, 0xBB]),
            displayName: "Other",
            publicKeyX963: Data(repeating: 0x04, count: 65),
            rpId: fixture.rpId,
            userName: "other",
        )

        let result = try PasskeyAssertionVerifier.verify(
            rpId: fixture.rpId,
            assertion: fixture.rawAssertion,
            expectedChallenge: fixture.challenge,
            candidates: [otherCredential, fixture.storedCredential],
        )

        XCTAssertEqual(result, fixture.storedCredential)
    }
}

// MARK: - AssertionFixture

/// Builds a real, cryptographically signed WebAuthn assertion fixture for testing
/// `PasskeyAssertionVerifier`, using `CryptoKit` to generate a genuine key pair and ECDSA
/// signature rather than hand-rolled bytes.
private struct AssertionFixture {
    let rpId: String
    let credentialId: Data
    let challenge: Data
    let rawAuthenticatorData: Data
    let rawClientDataJSON: Data
    let signature: Data
    let storedCredential: StoredPasskeyCredential

    var rawAssertion: PasskeyAssertionVerifier.RawAssertion {
        PasskeyAssertionVerifier.RawAssertion(
            credentialId: credentialId,
            rawAuthenticatorData: rawAuthenticatorData,
            signature: signature,
            rawClientDataJSON: rawClientDataJSON,
        )
    }

    static func valid(
        rpId: String = "bitwarden.pw",
        userPresent: Bool = true,
        clientDataType: String = "webauthn.get",
    ) throws -> AssertionFixture {
        let privateKey = P256.Signing.PrivateKey()
        let credentialId = Data([0x01, 0x02, 0x03, 0x04])
        let challenge = Data([0x10, 0x11, 0x12, 0x13])

        let rpIdHash = Data(SHA256.hash(data: Data(rpId.utf8)))
        let flags: UInt8 = userPresent ? 0x01 : 0x00
        let signCount = Data([0x00, 0x00, 0x00, 0x01])
        let rawAuthenticatorData = rpIdHash + Data([flags]) + signCount

        let challengeBase64URL = challenge.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        let clientDataJSONString = """
        {"type":"\(clientDataType)","challenge":"\(challengeBase64URL)","origin":"https://\(rpId)"}
        """
        let rawClientDataJSON = Data(clientDataJSONString.utf8)

        let clientDataHash = Data(SHA256.hash(data: rawClientDataJSON))
        let signedData = rawAuthenticatorData + clientDataHash
        let signature = try privateKey.signature(for: signedData).derRepresentation

        let storedCredential = StoredPasskeyCredential(
            createdAt: Date(timeIntervalSince1970: 0),
            credentialId: credentialId,
            displayName: "User",
            publicKeyX963: privateKey.publicKey.x963Representation,
            rpId: rpId,
            userName: "user",
        )

        return AssertionFixture(
            rpId: rpId,
            credentialId: credentialId,
            challenge: challenge,
            rawAuthenticatorData: rawAuthenticatorData,
            rawClientDataJSON: rawClientDataJSON,
            signature: signature,
            storedCredential: storedCredential,
        )
    }
}
