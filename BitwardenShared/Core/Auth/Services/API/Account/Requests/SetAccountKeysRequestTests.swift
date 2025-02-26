import XCTest

@testable import BitwardenShared

class SetAccountKeysRequestTests: BitwardenTestCase {
    // MARK: Properties

    var subject: SetAccountKeysRequest!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        subject = SetAccountKeysRequest(body: KeysRequestModel(
            encryptedPrivateKey: "PRIVATE_KEY",
            publicKey: "PUBLIC_KEY"
        )
        )
    }

    override func tearDown() {
        super.tearDown()

        subject = nil
    }

    // MARK: Tests

    /// `body` is the JSON encoded request model.
    func test_body() throws {
        let bodyData = try XCTUnwrap(subject.body?.encode())
        XCTAssertEqual(
            bodyData.prettyPrintedJson,
            """
            {
              "encryptedPrivateKey" : "PRIVATE_KEY",
              "publicKey" : "PUBLIC_KEY"
            }
            """
        )
    }

    /// `method` is `.post`.
    func test_method() {
        XCTAssertEqual(subject.method, .post)
    }

    /// `path` is the correct value.
    func test_path() {
        XCTAssertEqual(subject.path, "/accounts/keys")
    }
}
