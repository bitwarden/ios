import Networking
import XCTest

@testable import BitwardenShared

class SetKeyConnectorKeyRequestTests: BitwardenTestCase {
    // MARK: Properties

    let subject = SetKeyConnectorKeyRequest(
        requestModel: SetKeyConnectorKeyRequestModel(
            kdfConfig: KdfConfig(),
            key: "key",
            keys: KeysRequestModel(
                encryptedPrivateKey: "encrypted-private-key",
                publicKey: "public-key"
            ),
            orgIdentifier: "org-id"
        )
    )

    // MARK: Tests

    /// `body` is the JSON encoded request model.
    func test_body() throws {
        let bodyData = try XCTUnwrap(subject.body?.encode())
        XCTAssertEqual(
            bodyData.prettyPrintedJson,
            """
            {
              "kdf" : 0,
              "kdfIterations" : 600000,
              "key" : "key",
              "keys" : {
                "encryptedPrivateKey" : "encrypted-private-key",
                "publicKey" : "public-key"
              },
              "orgIdentifier" : "org-id"
            }
            """
        )
    }

    /// Validate that the method is correct.
    func test_method() {
        XCTAssertEqual(subject.method, .post)
    }

    /// Validate that the path is correct.
    func test_path() {
        XCTAssertEqual(subject.path, "/accounts/set-key-connector-key")
    }
}
