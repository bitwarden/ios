import BitwardenKit
import TestHelpers
import XCTest

@testable import TestHarnessShared

// MARK: - ClientDataJSONParserTests

/// Tests for `ClientDataJSONParser`.
///
class ClientDataJSONParserTests: BitwardenTestCase {
    // MARK: Tests

    /// `parse(fromClientDataJSON:)` extracts the type and base64url-decoded challenge from a
    /// well-formed payload.
    func test_parse_validPayload_returnsTypeAndChallenge() throws {
        let parsed = try ClientDataJSONParser.parse(fromClientDataJSON: .fixtureValid)

        XCTAssertEqual(parsed.type, "webauthn.create")
        XCTAssertEqual(parsed.challenge, Data([0x00, 0x01, 0x02, 0x03]))
    }

    /// `parse(fromClientDataJSON:)` throws when the payload isn't valid JSON.
    func test_parse_malformedJSON_throwsError() {
        let malformed = Data("not json".utf8)
        XCTAssertThrowsError(try ClientDataJSONParser.parse(fromClientDataJSON: malformed)) { error in
            XCTAssertEqual(error as? ClientDataJSONParser.ParsingError, .malformedJSON)
        }
    }

    /// `parse(fromClientDataJSON:)` throws when the payload is valid JSON but not a JSON object.
    func test_parse_jsonArray_throwsMalformedJSON() {
        let array = Data("[]".utf8)
        XCTAssertThrowsError(try ClientDataJSONParser.parse(fromClientDataJSON: array)) { error in
            XCTAssertEqual(error as? ClientDataJSONParser.ParsingError, .malformedJSON)
        }
    }

    /// `parse(fromClientDataJSON:)` throws when the `type` field is missing.
    func test_parse_missingType_throwsMissingType() {
        XCTAssertThrowsError(try ClientDataJSONParser.parse(fromClientDataJSON: .fixtureMissingType)) { error in
            XCTAssertEqual(error as? ClientDataJSONParser.ParsingError, .missingType)
        }
    }

    /// `parse(fromClientDataJSON:)` throws when the `challenge` field is missing.
    func test_parse_missingChallenge_throwsMissingChallenge() {
        XCTAssertThrowsError(try ClientDataJSONParser.parse(fromClientDataJSON: .fixtureMissingChallenge)) { error in
            XCTAssertEqual(error as? ClientDataJSONParser.ParsingError, .missingChallenge)
        }
    }

    /// `parse(fromClientDataJSON:)` throws when the `challenge` field isn't valid base64url.
    func test_parse_malformedChallengeEncoding_throwsMalformedChallengeEncoding() {
        XCTAssertThrowsError(
            try ClientDataJSONParser.parse(fromClientDataJSON: .fixtureMalformedChallenge),
        ) { error in
            XCTAssertEqual(error as? ClientDataJSONParser.ParsingError, .malformedChallengeEncoding)
        }
    }
}

// MARK: - Data+Fixtures

private extension Data {
    /// A well-formed `clientDataJSON` payload for a registration ceremony.
    static let fixtureValid = Data("""
    {"type":"webauthn.create","challenge":"AAECAw","origin":"https://bitwarden.com"}
    """.utf8)

    /// A `clientDataJSON` payload missing the `type` field.
    static let fixtureMissingType = Data("""
    {"challenge":"AAECAw","origin":"https://bitwarden.com"}
    """.utf8)

    /// A `clientDataJSON` payload missing the `challenge` field.
    static let fixtureMissingChallenge = Data("""
    {"type":"webauthn.create","origin":"https://bitwarden.com"}
    """.utf8)

    /// A `clientDataJSON` payload whose `challenge` field contains characters that aren't valid
    /// base64url.
    static let fixtureMalformedChallenge = Data("""
    {"type":"webauthn.create","challenge":"not-valid-base64url!!!","origin":"https://bitwarden.com"}
    """.utf8)
}
