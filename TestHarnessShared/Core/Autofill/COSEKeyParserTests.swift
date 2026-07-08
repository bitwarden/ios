import TestHelpers
import XCTest

@testable import TestHarnessShared

// MARK: - COSEKeyParserTests

/// Tests for `COSEKeyParser`.
///
class COSEKeyParserTests: BitwardenTestCase {
    // MARK: Tests

    /// `parseCredential(fromAttestationObject:)` extracts the credential ID and P-256 public key
    /// from a valid ES256 attestation object.
    func test_parseCredential_validES256Attestation_returnsCredentialIdAndPublicKey() throws {
        let parsed = try COSEKeyParser.parseCredential(fromAttestationObject: .fixtureValid)

        XCTAssertEqual(
            parsed.credentialId,
            Data(hex: "6465666768696a6b6c6d6e6f707172737475767778797a7b7c7d7e7f80818283"),
        )
        XCTAssertEqual(parsed.publicKeyX963.count, 65)
        XCTAssertEqual(parsed.publicKeyX963.first, 0x04)
        XCTAssertEqual(
            parsed.publicKeyX963,
            Data(
                hex: "040102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f202122232425" +
                    "262728292a2b2c2d2e2f303132333435363738393a3b3c3d3e3f40",
            ),
        )
    }

    /// `parseCredential(fromAttestationObject:)` throws when `authData` is truncated before the
    /// credential ID length field.
    func test_parseCredential_truncatedAuthData_throwsAuthDataTooShort() {
        XCTAssertThrowsError(
            try COSEKeyParser.parseCredential(fromAttestationObject: .fixtureTruncatedAuthData),
        ) { error in
            XCTAssertEqual(error as? COSEKeyParser.ParsingError, .authDataTooShort)
        }
    }

    /// `parseCredential(fromAttestationObject:)` throws when the COSE key's algorithm isn't ES256.
    func test_parseCredential_wrongAlgorithm_throwsUnsupportedAlgorithm() {
        XCTAssertThrowsError(
            try COSEKeyParser.parseCredential(fromAttestationObject: .fixtureWrongAlgorithm),
        ) { error in
            XCTAssertEqual(error as? COSEKeyParser.ParsingError, .unsupportedAlgorithm(-257))
        }
    }

    /// `parseCredential(fromAttestationObject:)` throws when the COSE key's curve isn't P-256.
    func test_parseCredential_wrongCurve_throwsUnsupportedCurve() {
        XCTAssertThrowsError(
            try COSEKeyParser.parseCredential(fromAttestationObject: .fixtureWrongCurve),
        ) { error in
            XCTAssertEqual(error as? COSEKeyParser.ParsingError, .unsupportedCurve(2))
        }
    }

    /// `parseCredential(fromAttestationObject:)` throws rather than crashing on malformed
    /// top-level CBOR.
    func test_parseCredential_malformedTopLevelCBOR_throwsError() {
        let malformed = Data([0xFF, 0x00, 0x01])
        XCTAssertThrowsError(try COSEKeyParser.parseCredential(fromAttestationObject: malformed))
    }

    /// `parseCredential(fromAttestationObject:)` throws when the top-level map has no `authData` key.
    func test_parseCredential_missingAuthDataKey_throwsError() {
        XCTAssertThrowsError(
            try COSEKeyParser.parseCredential(fromAttestationObject: .fixtureMissingAuthData),
        ) { error in
            XCTAssertEqual(error as? COSEKeyParser.ParsingError, .missingAuthData)
        }
    }

    /// `parseCredential(fromAttestationObject:)` succeeds even when extra bytes follow the COSE
    /// key, since the key's own declared length is authoritative.
    func test_parseCredential_extraTrailingBytesAfterCOSEKey_stillSucceeds() throws {
        let parsed = try COSEKeyParser.parseCredential(fromAttestationObject: .fixtureTrailingBytes)

        XCTAssertEqual(parsed.publicKeyX963.count, 65)
        XCTAssertEqual(parsed.publicKeyX963.first, 0x04)
    }
}

// MARK: - Data+Fixtures

private extension Data {
    /// A well-formed attestation object with a valid ES256/P-256 COSE key.
    static let fixtureValid = Data(
        base64Encoded: "o2NmbXRkbm9uZWdhdHRTdG10oGhhdXRoRGF0YViko3mm9u6vuaVeN4wRgDTidR5oL6ufLTCrE9IS" +
            "VYbOGUdBAAAAAAAAAAAAAAAAAAAAAAAAAAAAIGRlZmdoaWprbG1ub3BxcnN0dXZ3eHl6e3x9fn+A" +
            "gYKDpQECAyYgASFYIAECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGxwdHh8gIlggISIjJCUmJygp" +
            "KissLS4vMDEyMzQ1Njc4OTo7PD0+P0A=",
    )!

    /// An attestation object whose `authData` is truncated before the credential ID length field.
    static let fixtureTruncatedAuthData = Data(
        base64Encoded: "o2NmbXRkbm9uZWdhdHRTdG10oGhhdXRoRGF0YVgoo3mm9u6vuaVeN4wRgDTidR5oL6ufLTCrE9IS" +
            "VYbOGUdBAAAAAAAAAA==",
    )!

    /// An attestation object whose COSE key declares `alg = -257` instead of `-7` (ES256).
    static let fixtureWrongAlgorithm = Data(
        base64Encoded: "o2NmbXRkbm9uZWdhdHRTdG10oGhhdXRoRGF0YVimo3mm9u6vuaVeN4wRgDTidR5oL6ufLTCrE9IS" +
            "VYbOGUdBAAAAAAAAAAAAAAAAAAAAAAAAAAAAIGRlZmdoaWprbG1ub3BxcnN0dXZ3eHl6e3x9fn+A" +
            "gYKDpQECAzkBACABIVggAQIDBAUGBwgJCgsMDQ4PEBESExQVFhcYGRobHB0eHyAiWCAhIiMkJSYn" +
            "KCkqKywtLi8wMTIzNDU2Nzg5Ojs8PT4/QA==",
    )!

    /// An attestation object whose COSE key declares `crv = 2` instead of `1` (P-256).
    static let fixtureWrongCurve = Data(
        base64Encoded: "o2NmbXRkbm9uZWdhdHRTdG10oGhhdXRoRGF0YViko3mm9u6vuaVeN4wRgDTidR5oL6ufLTCrE9IS" +
            "VYbOGUdBAAAAAAAAAAAAAAAAAAAAAAAAAAAAIGRlZmdoaWprbG1ub3BxcnN0dXZ3eHl6e3x9fn+A" +
            "gYKDpQECAyYgAiFYIAECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGxwdHh8gIlggISIjJCUmJygp" +
            "KissLS4vMDEyMzQ1Njc4OTo7PD0+P0A=",
    )!

    /// A well-formed top-level attestation object map with no `authData` key.
    static let fixtureMissingAuthData = Data(
        base64Encoded: "omNmbXRkbm9uZWdhdHRTdG10oA==",
    )!

    /// An attestation object with 2 extra bytes appended after an otherwise-valid COSE key.
    static let fixtureTrailingBytes = Data(
        base64Encoded: "o2NmbXRkbm9uZWdhdHRTdG10oGhhdXRoRGF0YVimo3mm9u6vuaVeN4wRgDTidR5oL6ufLTCrE9IS" +
            "VYbOGUdBAAAAAAAAAAAAAAAAAAAAAAAAAAAAIGRlZmdoaWprbG1ub3BxcnN0dXZ3eHl6e3x9fn+A" +
            "gYKDpQECAyYgASFYIAECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGxwdHh8gIlggISIjJCUmJygp" +
            "KissLS4vMDEyMzQ1Njc4OTo7PD0+P0Cquw==",
    )!
}

private extension Data {
    /// Constructs `Data` from a hex string, for readable expected-value comparisons.
    init(hex: String) {
        var data = Data(capacity: hex.count / 2)
        var index = hex.startIndex
        while index < hex.endIndex {
            let nextIndex = hex.index(index, offsetBy: 2)
            data.append(UInt8(hex[index ..< nextIndex], radix: 16)!)
            index = nextIndex
        }
        self = data
    }
}
