import Networking
import XCTest

@testable import BitwardenShared

class ResendNewDeviceOtpRequestTests: BitwardenTestCase {
    // MARK: Properties

    var subject: ResendNewDeviceOtpRequest!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        subject = ResendNewDeviceOtpRequest(model: .init(
            email: "email",
            masterPasswordHash: "",
        ))
    }

    override func tearDown() {
        super.tearDown()

        subject = nil
    }

    // MARK: Tests

    /// `body` returns the body of the request.
    func test_body() throws {
        XCTAssertEqual(subject.body?.email, "email")
    }

    /// `method` returns the method of the request.
    func test_method() {
        XCTAssertEqual(subject.method, .post)
    }

    /// `path` returns the path of the request.
    func test_path() {
        XCTAssertEqual(subject.path, "/accounts/resend-new-device-otp")
    }
}
