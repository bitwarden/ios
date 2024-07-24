import Networking
import XCTest

@testable import BitwardenShared

// MARK: - StartRegistrationRequestTests

class StartRegistrationRequestTests: BitwardenTestCase {
    // MARK: Properties

    var subject: StartRegistrationRequest!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        subject = StartRegistrationRequest(
            body: StartRegistrationRequestModel(
                email: "example@email.com",
                name: "key",
                receiveMarketingEmails: true
            )
        )
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
        XCTAssertEqual(subject.path, "/accounts/register/send-verification-email")
    }

    /// Validate that the body is not nil.
    func test_body() {
        XCTAssertNotNil(subject.body)
    }

    /// `validate(_:)` with a `400` status code but no captcha error does not throw a validation error.
    func test_validate_with400() {
        let response = HTTPResponse.failure(
            statusCode: 400,
            body: Data("example data".utf8)
        )

        XCTAssertNoThrow(try subject.validate(response))
    }

    /// `validate(_:)` with a valid response does not throw a validation error.
    func test_validate_with200() {
        let response = HTTPResponse.success(
            body: APITestData.startRegistrationSuccess.data
        )

        XCTAssertNoThrow(try subject.validate(response))
    }

    // MARK: Init

    /// Validate that the value provided to the init method is correct.
    func test_init_body() {
        XCTAssertEqual(subject.body?.email, "example@email.com")
    }
}
