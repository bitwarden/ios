import Networking
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
        let subject = RegisterFinishRequest(
            body: RegisterFinishRequestModel(
                email: "example@email.com",
                kdfConfig: KdfConfig(),
                masterPasswordHash: "1a2b3c",
                masterPasswordHint: "hint",
                userSymmetricKey: "key",
                userAsymmetricKeys: KeysRequestModel(encryptedPrivateKey: "private")
            )
        )
        XCTAssertEqual(subject.method, .post)
    }

    /// Validate that the path is correct.
    func test_path() {
        let subject = RegisterFinishRequest(
            body: RegisterFinishRequestModel(
                email: "example@email.com",
                kdfConfig: KdfConfig(),
                masterPasswordHash: "1a2b3c",
                masterPasswordHint: "hint",
                userSymmetricKey: "key",
                userAsymmetricKeys: KeysRequestModel(encryptedPrivateKey: "private")
            )
        )
        XCTAssertEqual(subject.path, "/accounts/register/finish")
    }

    /// Validate that the path is correct when there is an email verification token.
    func test_path_with_token() {
        let subject = RegisterFinishRequest(
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
        XCTAssertEqual(subject.path, "/accounts/register/finish")
    }

    /// Validate that the body is not nil.
    func test_body() {
        let subject = RegisterFinishRequest(
            body: RegisterFinishRequestModel(
                email: "example@email.com",
                kdfConfig: KdfConfig(),
                masterPasswordHash: "1a2b3c",
                masterPasswordHint: "hint",
                userSymmetricKey: "key",
                userAsymmetricKeys: KeysRequestModel(encryptedPrivateKey: "private")
            )
        )
        XCTAssertNotNil(subject.body)
    }

    /// `validate(_:)` with a `400` status code and an account already exists error in the response body
    /// throws an `.accountAlreadyExists` error.
    func test_validate_with400AccountAlreadyExists() throws {
        let response = HTTPResponse.failure(
            statusCode: 400,
            body: APITestData.createAccountAccountAlreadyExists.data
        )

        guard let errorResponse = try? ErrorResponseModel(response: response) else { return }

        XCTAssertThrowsError(try subject.validate(response)) { error in
            XCTAssertEqual(error as? ServerError, .error(errorResponse: errorResponse))
        }
    }

    /// `validate(_:)` with a `400` status code and captcha error in the response body throws a `.captchaRequired`
    /// error.
    func test_validate_with400CaptchaError() {
        let response = HTTPResponse.failure(
            statusCode: 400,
            body: APITestData.createAccountCaptchaFailure.data
        )

        XCTAssertThrowsError(try subject.validate(response)) { error in
            XCTAssertEqual(
                error as? RegisterFinishRequestError,
                .captchaRequired(hCaptchaSiteCode: "bc38c8a2-5311-4e8c-9dfc-49e99f6df417")
            )
        }
    }

    /// `validate(_:)` with a `400` status code and an invalid email format error in the response body
    /// throws an `.invalidEmailFormat` error.
    func test_validate_with400InvalidEmailFormat() {
        let response = HTTPResponse.failure(
            statusCode: 400,
            body: APITestData.createAccountInvalidEmailFormat.data
        )

        guard let errorResponse = try? ErrorResponseModel(response: response) else { return }

        XCTAssertThrowsError(try subject.validate(response)) { error in
            XCTAssertEqual(error as? ServerError, .error(errorResponse: errorResponse))
        }
    }

    /// `validate(_:)` with a `400` status code but no captcha error does not throw a validation error.
    func test_validate_with400NonCaptchaError() {
        let response = HTTPResponse.failure(
            statusCode: 400,
            body: Data("example data".utf8)
        )

        XCTAssertNoThrow(try subject.validate(response))
    }

    /// `validate(_:)` with a valid response does not throw a validation error.
    func test_validate_with200() {
        let response = HTTPResponse.success(
            body: APITestData.createAccountSuccess.data
        )

        XCTAssertNoThrow(try subject.validate(response))
    }

    // MARK: Init

    /// Validate that the value provided to the init method is correct.
    func test_init_body() {
        let subject = RegisterFinishRequest(
            body: RegisterFinishRequestModel(
                email: "example@email.com",
                kdfConfig: KdfConfig(),
                masterPasswordHash: "1a2b3c",
                masterPasswordHint: "hint",
                userSymmetricKey: "key",
                userAsymmetricKeys: KeysRequestModel(encryptedPrivateKey: "private")
            )
        )
        XCTAssertEqual(subject.body?.email, "example@email.com")
    }
}
