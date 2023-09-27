import XCTest

@testable import BitwardenShared

class TokenParserTests: BitwardenTestCase {
    // MARK: Tests

    /// `parseToken(_:)` parses the payload data of the JWT token.
    func test_parse_token() throws {
        // swiftlint:disable:next line_length
        let token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMzUxMjQ2Ny05Y2ZlLTQzYjAtOTY5Zi0wNzUzNDA4NDc2NGIiLCJuYW1lIjoiQml0d2FyZGVuIFVzZXIiLCJlbWFpbCI6InVzZXJAYml0d2FyZGVuLmNvbSIsImlhdCI6MTUxNjIzOTAyMiwicHJlbWl1bSI6ZmFsc2V9.Pbd74CpalStTjFTvUBaxmHkl4Z0gwVLHATVFIzvYpjE"

        let payload = try TokenParser.parseToken(token)

        XCTAssertEqual(
            payload,
            TokenPayload(
                email: "user@bitwarden.com",
                hasPremium: false,
                name: "Bitwarden User",
                userId: "13512467-9cfe-43b0-969f-07534084764b"
            )
        )
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
