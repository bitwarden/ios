import XCTest

@testable import BitwardenShared

class VerifyUserEmailRequestTests: BitwardenTestCase {
    // MARK: Properties

    var subject: VerifyUserEmailRequest!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        subject = VerifyUserEmailRequest(
            requestModel: VerifyUserEmailRequestModel(
                email: "email@example.com",
                emailVerificationToken: "thisisaveryficationtoken"
            ))
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
              "email" : "email@example.com",
              "emailVerificationToken" : "thisisaveryficationtoken"
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
        XCTAssertEqual(subject.path, "/accounts/verify-email")
    }
}
