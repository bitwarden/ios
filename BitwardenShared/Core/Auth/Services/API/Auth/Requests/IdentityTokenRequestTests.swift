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
                clientType: .mobile,
                deviceInfo: .fixture()
            )
        )

        subjectPassword = IdentityTokenRequest(
            requestModel: IdentityTokenRequestModel(
                authenticationMethod: .password(username: "user@example.com", password: "password"),
                captchaToken: "captchaToken",
                clientType: .mobile,
                deviceInfo: .fixture()
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
                "deviceName=iPhone%2014&devicePushToken=pushToken&deviceType=1&" +
                "grant%5Ftype=authorization%5Fcode&code=code&code%5Fverifier=codeVerifier&" +
                "redirect%5Furi=redirectUri&captchaResponse=captchaToken"
        )
    }

    /// `body` returns the URL encoded form data for a password request.
    func test_body_password() throws {
        let bodyData = try XCTUnwrap(subjectPassword.body?.encode())
        XCTAssertEqual(
            String(data: bodyData, encoding: .utf8),
            "scope=api%20offline%5Faccess&client%5Fid=mobile&deviceIdentifier=1234&" +
                "deviceName=iPhone%2014&devicePushToken=pushToken&deviceType=1&" +
                "grant%5Ftype=password&username=user%40example%2Ecom&password=password&" +
                "captchaResponse=captchaToken"
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
}
