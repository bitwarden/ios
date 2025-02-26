import Networking
import XCTest

@testable import BitwardenShared

class ResendEmailCodeRequestTests: BitwardenTestCase {
    // MARK: Properties

    var subject: ResendEmailCodeRequest!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        subject = ResendEmailCodeRequest(model: .init(
            deviceIdentifier: "id",
            email: "email",
            masterPasswordHash: nil,
            ssoEmail2FaSessionToken: nil
        ))
    }

    override func tearDown() {
        super.tearDown()

        subject = nil
    }

    // MARK: Tests

    /// `body` returns the body of the request.
    func test_body() throws {
        XCTAssertEqual(subject.body?.deviceIdentifier, "id")
        XCTAssertEqual(subject.body?.email, "email")
    }

    /// `method` returns the method of the request.
    func test_method() {
        XCTAssertEqual(subject.method, .post)
    }

    /// `path` returns the path of the request.
    func test_path() {
        XCTAssertEqual(subject.path, "/two-factor/send-email-login")
    }
}
