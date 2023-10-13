import XCTest

@testable import BitwardenShared

class TokenParserTests: BitwardenTestCase {
    // MARK: Tests

    /// `parseToken(_:)` parses the payload data of the JWT token.
    func test_parse_token() throws {
        // swiftlint:disable:next line_length
        let token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE2OTY5MDg4NzksInN1YiI6IjEzNTEyNDY3LTljZmUtNDNiMC05NjlmLTA3NTM0MDg0NzY0YiIsIm5hbWUiOiJCaXR3YXJkZW4gVXNlciIsImVtYWlsIjoidXNlckBiaXR3YXJkZW4uY29tIiwiZW1haWxfdmVyaWZpZWQiOnRydWUsImlhdCI6MTUxNjIzOTAyMiwicHJlbWl1bSI6ZmFsc2UsImFtciI6WyJBcHBsaWNhdGlvbiJdfQ.KDqC8kUaOAgBiUY8eeLa0a4xYWN8GmheXTFXmataFwM"

        let payload = try TokenParser.parseToken(token)

        XCTAssertEqual(
            payload,
            TokenPayload(
                authenticationMethodsReference: ["Application"],
                email: "user@bitwarden.com",
                emailVerified: true,
                expirationTimeIntervalSince1970: 1_696_908_879,
                hasPremium: false,
                name: "Bitwarden User",
                userId: "13512467-9cfe-43b0-969f-07534084764b"
            )
        )
        XCTAssertEqual(payload.expirationDate, Date(timeIntervalSince1970: 1_696_908_879))
        XCTAssertFalse(payload.isExternal)
    }

    /// `parseToken(_:)` parses the payload data of the JWT token for an external user.
    func test_parse_token_external() throws {
        // swiftlint:disable:next line_length
        let token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE2OTY5MDg4NzksInN1YiI6IjEzNTEyNDY3LTljZmUtNDNiMC05NjlmLTA3NTM0MDg0NzY0YiIsIm5hbWUiOiJCaXR3YXJkZW4gVXNlciIsImVtYWlsIjoidXNlckBiaXR3YXJkZW4uY29tIiwiZW1haWxfdmVyaWZpZWQiOnRydWUsImlhdCI6MTUxNjIzOTAyMiwicHJlbWl1bSI6ZmFsc2UsImFtciI6WyJleHRlcm5hbCJdfQ.POnwEWm09reMUfiHKZP-PIW_fvIl-ZzXs9pLZJVYf9A"

        let payload = try TokenParser.parseToken(token)

        XCTAssertEqual(
            payload,
            TokenPayload(
                authenticationMethodsReference: ["external"],
                email: "user@bitwarden.com",
                emailVerified: true,
                expirationTimeIntervalSince1970: 1_696_908_879,
                hasPremium: false,
                name: "Bitwarden User",
                userId: "13512467-9cfe-43b0-969f-07534084764b"
            )
        )
        XCTAssertEqual(payload.expirationDate, Date(timeIntervalSince1970: 1_696_908_879))
        XCTAssertTrue(payload.isExternal)
    }

    /// `parseToken(_:)` throws an error if there's invalid data in the JWT token.
    func test_parse_invalidData() {
        let token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.%12.👻"
        XCTAssertThrowsError(try TokenParser.parseToken(token)) { error in
            XCTAssertEqual(error as? TokenParserError, .invalidToken)
        }
    }

    /// `parseToken(_:)` throws an error if there's an invalid number of parts in the JWT token.
    func test_parse_invalidParts() {
        let token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9"
        XCTAssertThrowsError(try TokenParser.parseToken(token)) { error in
            XCTAssertEqual(error as? TokenParserError, .invalidToken)
        }
    }
}
