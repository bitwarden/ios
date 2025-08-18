import BitwardenKit
import Networking
import TestHelpers
import XCTest

@testable import BitwardenShared

// MARK: - RegisterFinishRequestTests

class RegisterFinishRequestTests: BitwardenTestCase {
    // MARK: Properties

    var subject: RegisterFinishRequest!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        subject = RegisterFinishRequest(
            body: RegisterFinishRequestModel(
                email: "example@email.com",
                emailVerificationToken: "thisisanawesometoken",
                kdfConfig: KdfConfig(),
                masterPasswordHash: "1a2b3c",
                masterPasswordHint: "hint",
                userSymmetricKey: "key",
                userAsymmetricKeys: KeysRequestModel(encryptedPrivateKey: "private")
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
        XCTAssertEqual(subject.path, "/accounts/register/finish")
    }

    /// Validate that the body is not nil.
    func test_body() {
        XCTAssertNotNil(subject.body)
    }

    /// `validate(_:)` with a `400` status code does not throw a validation error.
    func test_validate_with400Error() {
        let response = HTTPResponse.failure(
            statusCode: 400,
            body: Data("example data".utf8)
        )

        XCTAssertNoThrow(try subject.validate(response))
    }

    /// `validate(_:)` with a valid response does not throw a validation error.
    func test_validate_with200() {
        let response = HTTPResponse.success(
            body: APITestData.registerFinishSuccess.data
        )

        XCTAssertNoThrow(try subject.validate(response))
    }

    // MARK: Init

    /// Validate that the value provided to the init method is correct.
    func test_init_body() {
        XCTAssertEqual(subject.body?.email, "example@email.com")
    }
}
