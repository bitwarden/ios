import XCTest

@testable import BitwardenShared

class UpdateTempPasswordRequestTests: BitwardenTestCase {
    // MARK: Properties

    var subject: UpdateTempPasswordRequest!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        subject = UpdateTempPasswordRequest(
            requestModel: UpdateTempPasswordRequestModel(
                key: "KEY",
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
              "masterPasswordHint" : "MASTER_PASSWORD_HINT",
              "newMasterPasswordHash" : "NEW_MASTER_PASSWORD_HASH"
            }
            """
        )
    }

    /// `method` is `.put`.
    func test_method() {
        XCTAssertEqual(subject.method, .put)
    }

    /// `path` is the correct value.
    func test_path() {
        XCTAssertEqual(subject.path, "/accounts/update-temp-password")
    }
}
