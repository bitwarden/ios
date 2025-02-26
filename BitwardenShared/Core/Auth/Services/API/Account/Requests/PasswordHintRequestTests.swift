import Networking
import XCTest

@testable import BitwardenShared

// MARK: - PasswordHintRequestTests

class PasswordHintRequestTests: BitwardenTestCase {
    // MARK: Properties

    var subject: PasswordHintRequest!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        subject = PasswordHintRequest(body: PasswordHintRequestModel(email: "email@example.com"))
    }

    override func tearDown() {
        super.tearDown()

        subject = nil
    }

    // MARK: Tests

    /// Validate that the method is correct.
    func test_method() {
        XCTAssertEqual(subject.method, .post)
    }

    /// Validate that the path is correct.
    func test_path() {
        XCTAssertEqual(subject.path, "/accounts/password-hint")
    }
}
