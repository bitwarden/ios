import TestHelpers
import XCTest

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - WebAuthnLoginCredentialCreationOptionsResponseTests

class WebAuthnLoginCredentialCreationOptionsResponseTests: BitwardenTestCase {
    // MARK: Decoding

    /// Validates decoding the `WebAuthnLoginCredentialCreationOptions.json` fixture.
    func test_decode() throws {
        let json = APITestData.webAuthnLoginCredentialCreationOptions.data
        let decoder = JSONDecoder()
        let subject = try decoder.decode(
            WebAuthnLoginCredentialCreationOptionsResponse.self,
            from: json,
        )

        XCTAssertEqual(subject.options.challenge, "dGVzdC1jaGFsbGVuZ2U")
        XCTAssertEqual(subject.options.rp.id, "example.com")
        XCTAssertEqual(subject.options.rp.name, "Example RP")
        XCTAssertEqual(subject.options.user.id, "dXNlci0xMjM=")
        XCTAssertEqual(subject.options.user.name, "user@example.com")
        XCTAssertEqual(subject.options.timeout, 60000)
        XCTAssertEqual(subject.options.pubKeyCredParams.count, 2)
        XCTAssertEqual(subject.options.pubKeyCredParams[0].alg, -7)
        XCTAssertEqual(subject.options.pubKeyCredParams[0].type, "public-key")
        XCTAssertEqual(subject.options.pubKeyCredParams[1].alg, -257)

        XCTAssertEqual(subject.options.excludeCredentials?.count, 1)
        XCTAssertEqual(subject.options.excludeCredentials?[0].id, "Y3JlZGVudGlhbC0x")
        XCTAssertEqual(subject.options.excludeCredentials?[0].type, "public-key")

        XCTAssertEqual(subject.options.extensions?.prf?.eval?.first, "cHJmLWZpcnN0")
        XCTAssertEqual(subject.options.extensions?.prf?.eval?.second, "cHJmLXNlY29uZA")
        XCTAssertNil(subject.options.extensions?.prf?.evalByCredential)

        XCTAssertNotNil(subject.token)
    }

    /// Validates that decoding succeeds when optional fields are absent.
    func test_decode_minimal() throws {
        let json = """
        {
          "options": {
            "challenge": "dGVzdC1jaGFsbGVuZ2U=",
            "pubKeyCredParams": [{"alg": -7, "type": "public-key"}],
            "rp": {"id": "example.com", "name": "Example RP"},
            "user": {"id": "dXNlci0xMjM=", "name": "user@example.com"}
          },
          "token": "2.test|iv|data"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let subject = try decoder.decode(
            WebAuthnLoginCredentialCreationOptionsResponse.self,
            from: json,
        )

        XCTAssertEqual(subject.options.challenge, "dGVzdC1jaGFsbGVuZ2U=")
        XCTAssertNil(subject.options.excludeCredentials)
        XCTAssertNil(subject.options.extensions)
        XCTAssertNil(subject.options.timeout)
        XCTAssertEqual(subject.options.pubKeyCredParams.count, 1)
        XCTAssertNotNil(subject.token)
    }
}
