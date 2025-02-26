import XCTest

@testable import BitwardenShared

class VerifyOtpRequestTests: BitwardenTestCase {
    // MARK: Properties

    var subject: VerifyOtpRequest!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        subject = VerifyOtpRequest(requestModel: VerifyOtpRequestModel(otp: "OTP"))
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
              "otp" : "OTP"
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
        XCTAssertEqual(subject.path, "/accounts/verify-otp")
    }
}
