import InlineSnapshotTesting
import XCTest

@testable import BitwardenShared

class UpdatePasswordRequestTests: BitwardenTestCase {
    // MARK: Properties

    var subject: UpdatePasswordRequest!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        subject = UpdatePasswordRequest(
            requestModel: UpdatePasswordRequestModel(
                key: "KEY",
                masterPasswordHash: "MASTER_PASSWORD_HASH",
                masterPasswordHint: "MASTER_PASSWORD_HINT",
                newMasterPasswordHash: "NEW_MASTER_PASSWORD_HASH"
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
              "key" : "KEY",
              "masterPasswordHash" : "MASTER_PASSWORD_HASH",
              "masterPasswordHint" : "MASTER_PASSWORD_HINT",
              "newMasterPasswordHash" : "NEW_MASTER_PASSWORD_HASH"
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
        XCTAssertEqual(subject.path, "/accounts/password")
    }
}
