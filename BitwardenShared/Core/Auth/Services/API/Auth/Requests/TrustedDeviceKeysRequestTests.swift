import XCTest

@testable import BitwardenShared

class TrustedDeviceKeysRequestTests: BitwardenTestCase {
    // MARK: Properties

    var subject: TrustedDeviceKeysRequest!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        subject = TrustedDeviceKeysRequest(
            deviceIdentifier: "ID",
            requestModel: TrustedDeviceKeysRequestModel(
                encryptedPrivateKey: "PRIVATE_KEY",
                encryptedPublicKey: "PUBLIC_KEY",
                encryptedUserKey: "USER_KEY"
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
              "encryptedPublicKey" : "PUBLIC_KEY",
              "encryptedUserKey" : "USER_KEY"
            }
            """
        )
    }

    /// `method` is `.post`.
    func test_method() {
        XCTAssertEqual(subject.method, .put)
    }

    /// `path` is the correct value.
    func test_path() {
        XCTAssertEqual(subject.path, "/devices/\(subject.deviceIdentifier)/keys")
    }
}
