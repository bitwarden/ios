import TestHelpers
import XCTest

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - WebAuthnLoginCredentialAssertionOptionsResponseTests

class WebAuthnLoginCredentialAssertionOptionsResponseTests: BitwardenTestCase {
    // MARK: Decoding

    /// Validates decoding the `WebAuthnLoginCredentialAssertionOptions.json` fixture.
    func test_decode() throws {
        let json = APITestData.webAuthnLoginCredentialAssertionOptions.data
        let decoder = JSONDecoder()
        let subject = try decoder.decode(
            WebAuthnLoginCredentialAssertionOptionsResponse.self,
            from: json,
        )

        XCTAssertEqual(subject.options.challenge, "YXNzZXJ0aW9uLWNoYWxsZW5nZQ==")
        XCTAssertEqual(subject.options.rpId, "example.com")
        XCTAssertEqual(subject.options.timeout, 60000)

        XCTAssertEqual(subject.options.allowCredentials?.count, 1)
        XCTAssertEqual(subject.options.allowCredentials?[0].id, "Y3JlZGVudGlhbC0x")
        XCTAssertEqual(subject.options.allowCredentials?[0].type, "public-key")

        XCTAssertEqual(subject.options.extensions?.prf?.eval?.first, "cHJmLWZpcnN0")
        XCTAssertNil(subject.options.extensions?.prf?.eval?.second)

        let evalByCredential = subject.options.extensions?.prf?.evalByCredential
        XCTAssertEqual(evalByCredential?.count, 1)
        XCTAssertEqual(evalByCredential?["Y3JlZGVudGlhbC0x"]?.first, "Y3JlZC1wcmYtZmlyc3Q=")
        XCTAssertEqual(evalByCredential?["Y3JlZGVudGlhbC0x"]?.second, "Y3JlZC1wcmYtc2Vjb25k")

        XCTAssertNotNil(subject.token)
    }

    /// Validates that decoding succeeds when optional fields are absent.
    func test_decode_minimal() throws {
        let json = """
        {
          "options": {
            "challenge": "YXNzZXJ0aW9uLWNoYWxsZW5nZQ==",
            "rpId": "example.com"
          },
          "token": "2.test|iv|data"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let subject = try decoder.decode(
            WebAuthnLoginCredentialAssertionOptionsResponse.self,
            from: json,
        )

        XCTAssertEqual(subject.options.challenge, "YXNzZXJ0aW9uLWNoYWxsZW5nZQ==")
        XCTAssertEqual(subject.options.rpId, "example.com")
        XCTAssertNil(subject.options.allowCredentials)
        XCTAssertNil(subject.options.extensions)
        XCTAssertNil(subject.options.timeout)
        XCTAssertNotNil(subject.token)
    }
}
