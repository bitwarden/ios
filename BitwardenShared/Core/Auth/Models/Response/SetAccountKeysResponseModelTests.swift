import TestHelpers
import XCTest

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - SetAccountKeysResponseModelTests

class SetAccountKeysResponseModelTests: BitwardenTestCase {
    // MARK: - Tests

    /// Tests the successful decoding of a JSON response without accountKeys.
    func test_decode_success_withoutAccountKeys() throws {
        let json = """
        {
          "key": null,
          "publicKey": "mockPublicKey",
          "privateKey": "mockPrivateKey",
          "accountKeys": null
        }
        """.data(using: .utf8)!

        let subject = try SetAccountKeysResponseModel.decoder.decode(
            SetAccountKeysResponseModel.self,
            from: json,
        )
        XCTAssertNil(subject.key)
        XCTAssertEqual(subject.publicKey, "mockPublicKey")
        XCTAssertEqual(subject.privateKey, "mockPrivateKey")
        XCTAssertNil(subject.accountKeys)
    }

    /// Tests the successful decoding of a JSON response with accountKeys.
    func test_decode_success_withAccountKeys() throws {
        let json = """
        {
          "key": "mockKey",
          "publicKey": "mockPublicKey",
          "privateKey": "mockPrivateKey",
          "accountKeys": {
            "signatureKeyPair": null,
            "publicKeyEncryptionKeyPair": {
              "wrappedPrivateKey": "mockWrappedPrivateKey",
              "publicKey": "mockPublicKey",
              "signedPublicKey": null
            },
            "securityState": null
          }
        }
        """.data(using: .utf8)!

        let subject = try SetAccountKeysResponseModel.decoder.decode(
            SetAccountKeysResponseModel.self,
            from: json,
        )
        XCTAssertEqual(subject.key, "mockKey")
        XCTAssertEqual(subject.publicKey, "mockPublicKey")
        XCTAssertEqual(subject.privateKey, "mockPrivateKey")
        XCTAssertNotNil(subject.accountKeys)
        XCTAssertEqual(subject.accountKeys?.publicKeyEncryptionKeyPair.wrappedPrivateKey, "mockWrappedPrivateKey")
    }

    /// Tests the model conforms to `AccountKeysResponseModelProtocol`.
    func test_accountKeysResponseModelProtocol() {
        let subject = SetAccountKeysResponseModel.fixture(
            accountKeys: .fixture(),
            key: "KEY",
            privateKey: "PRIVATE_KEY",
        )

        // Verify the protocol properties are accessible.
        XCTAssertEqual(subject.key, "KEY")
        XCTAssertEqual(subject.privateKey, "PRIVATE_KEY")
        XCTAssertNotNil(subject.accountKeys)
    }
}
