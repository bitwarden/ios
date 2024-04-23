import XCTest

@testable import BitwardenShared

class RequestOtpRequestTests: BitwardenTestCase {
    // MARK: Properties

    var subject: RequestOtpRequest!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        subject = RequestOtpRequest()
    }

    override func tearDown() {
        super.tearDown()

        subject = nil
    }

    // MARK: Tests

    /// `method` is `.post`.
    func test_method() {
        XCTAssertEqual(subject.method, .post)
    }

    /// `path` is the correct value.
    func test_path() {
        XCTAssertEqual(subject.path, "/accounts/request-otp")
    }
}
