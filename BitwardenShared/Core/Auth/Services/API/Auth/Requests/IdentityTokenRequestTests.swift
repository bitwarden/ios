import Networking
import XCTest

@testable import BitwardenShared

class IdentityTokenRequestTests: BitwardenTestCase {
    // MARK: Properties

    var subjectAuthorizationCode: IdentityTokenRequest!
    var subjectPassword: IdentityTokenRequest!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        subjectAuthorizationCode = IdentityTokenRequest(
            requestModel: IdentityTokenRequestModel(
                authenticationMethod: .authorizationCode(
                    code: "code",
                    codeVerifier: "codeVerifier",
                    redirectUri: "redirectUri"
                ),
                captchaToken: "captchaToken",
                deviceInfo: .fixture(),
                loginRequestId: nil
            )
        )

        subjectPassword = IdentityTokenRequest(
            requestModel: IdentityTokenRequestModel(
                authenticationMethod: .password(username: "user@example.com", password: "password"),
                captchaToken: "captchaToken",
                deviceInfo: .fixture(),
                loginRequestId: nil
            )
        )
    }

    override func tearDown() {
        super.tearDown()

        subjectAuthorizationCode = nil
        subjectPassword = nil
    }

    // MARK: Tests

    /// `body` returns the URL encoded form data for an authorization code request.
    func test_body_authorizationCode() throws {
        let bodyData = try XCTUnwrap(subjectAuthorizationCode.body?.encode())
        XCTAssertEqual(
            String(data: bodyData, encoding: .utf8),
            "scope=api%20offline%5Faccess&client%5Fid=mobile&deviceIdentifier=1234&" +
                "deviceName=iPhone%2014&deviceType=1&grant%5Ftype=authorization%5Fcode&code=code&" +
                "code%5Fverifier=codeVerifier&redirect%5Furi=redirectUri&captchaResponse=captchaToken"
        )
    }

    /// `body` returns the URL encoded form data for a password request.
    func test_body_password() throws {
        let bodyData = try XCTUnwrap(subjectPassword.body?.encode())
        XCTAssertEqual(
            String(data: bodyData, encoding: .utf8),
            "scope=api%20offline%5Faccess&client%5Fid=mobile&deviceIdentifier=1234&" +
                "deviceName=iPhone%2014&deviceType=1&grant%5Ftype=password&" +
                "username=user%40example%2Ecom&password=password&captchaResponse=captchaToken"
        )
    }

    /// `headers` returns no headers for an authorization code request.
    func test_headers_authorizationCode() {
        XCTAssertTrue(subjectAuthorizationCode.headers.isEmpty)
    }

    /// `headers` returns the headers needed for a password request.
    func test_headers_password() {
        XCTAssertEqual(subjectPassword.headers, ["Auth-Email": "dXNlckBleGFtcGxlLmNvbQ"])
    }

    /// `method` returns the method of the request.
    func test_method() {
        XCTAssertEqual(subjectAuthorizationCode.method, .post)
        XCTAssertEqual(subjectPassword.method, .post)
    }

    /// `path` returns the path of the request.
    func test_path() {
        XCTAssertEqual(subjectAuthorizationCode.path, "/connect/token")
        XCTAssertEqual(subjectPassword.path, "/connect/token")
    }

    /// `query` returns no query parameters.
    func test_query() {
        XCTAssertTrue(subjectAuthorizationCode.query.isEmpty)
        XCTAssertTrue(subjectPassword.query.isEmpty)
    }

    /// `validate(_:)` with a `400` status code and captcha error in the response body throws a `.captchaRequired`
    /// error.
    func test_validate_with400CaptchaError() {
        let response = HTTPResponse.failure(
            statusCode: 400,
            body: APITestData.identityTokenCaptchaError.data
        )

        XCTAssertThrowsError(try subjectAuthorizationCode.validate(response)) { error in
            XCTAssertEqual(error as? IdentityTokenRequestError, .captchaRequired(hCaptchaSiteCode: "1234"))
        }
    }

    /// `validate(_:)` with a `400` status code but no captcha error does not throw a validation error.
    func test_validate_with400NonCaptchaError() {
        let response = HTTPResponse.failure(
            statusCode: 400,
            body: Data("example data".utf8)
        )

        XCTAssertNoThrow(try subjectAuthorizationCode.validate(response))
    }

    /// `validate(_:)` with a `400` status code and two-factor error in the response body throws a `.twoFactorRequired`
    /// error.
    func test_validate_with400TwoFactorError() {
        let response = HTTPResponse.failure(
            statusCode: 400,
            body: APITestData.identityTokenTwoFactorError.data
        )

        XCTAssertThrowsError(try subjectAuthorizationCode.validate(response)) { error in
            XCTAssertEqual(
                error as? IdentityTokenRequestError,
                .twoFactorRequired(
                    AuthMethodsData.fixture(),
                    "exampleToken",
                    "BWCaptchaBypass_ABCXYZ"
                )
            )
        }
    }

    /// `validate(_:)` with a valid response does not throw a validation error.
    func test_validate_with200() {
        let response = HTTPResponse.success(
            body: APITestData.identityTokenSuccess.data
        )

        XCTAssertNoThrow(try subjectAuthorizationCode.validate(response))
    }
}
