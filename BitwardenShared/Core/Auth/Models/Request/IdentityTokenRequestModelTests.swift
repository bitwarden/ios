import XCTest

@testable import BitwardenShared

class IdentityTokenRequestModelTests: BitwardenTestCase {
    // MARK: Properties

    var subjectAuthorizationCode: IdentityTokenRequestModel!
    var subjectPassword: IdentityTokenRequestModel!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        subjectAuthorizationCode = IdentityTokenRequestModel(
            authenticationMethod: .authorizationCode(
                code: "code",
                codeVerifier: "codeVerifier",
                redirectUri: "redirectUri"
            ),
            captchaToken: "captchaToken",
            deviceInfo: .fixture()
        )

        subjectPassword = IdentityTokenRequestModel(
            authenticationMethod: .password(username: "user@example.com", password: "password"),
            captchaToken: "captchaToken",
            deviceInfo: .fixture()
        )
    }

    override func tearDown() {
        super.tearDown()

        subjectAuthorizationCode = nil
        subjectPassword = nil
    }

    // MARK: Tests

    /// `values` returns the form values to be encoded in the body for an authorization code request.
    func test_values_authorizationCode() {
        let valuesByKey = valuesByKey(subjectAuthorizationCode.values)

        XCTAssertEqual(valuesByKey.count, 10)

        XCTAssertEqual(valuesByKey["scope"], "api offline_access")
        XCTAssertEqual(valuesByKey["client_id"], "mobile")

        XCTAssertEqual(valuesByKey["deviceIdentifier"], "1234")
        XCTAssertEqual(valuesByKey["deviceName"], "iPhone 14")
        XCTAssertEqual(valuesByKey["deviceType"], "1")

        XCTAssertEqual(valuesByKey["grant_type"], "authorization_code")
        XCTAssertEqual(valuesByKey["code"], "code")
        XCTAssertEqual(valuesByKey["code_verifier"], "codeVerifier")
        XCTAssertEqual(valuesByKey["redirect_uri"], "redirectUri")
    }

    /// `values` returns the form values to be encoded in the body for a password request.
    func test_values_password() {
        let valuesByKey = valuesByKey(subjectPassword.values)

        XCTAssertEqual(valuesByKey.count, 9)

        XCTAssertEqual(valuesByKey["scope"], "api offline_access")
        XCTAssertEqual(valuesByKey["client_id"], "mobile")

        XCTAssertEqual(valuesByKey["deviceIdentifier"], "1234")
        XCTAssertEqual(valuesByKey["deviceName"], "iPhone 14")
        XCTAssertEqual(valuesByKey["deviceType"], "1")

        XCTAssertEqual(valuesByKey["grant_type"], "password")
        XCTAssertEqual(valuesByKey["username"], "user@example.com")
        XCTAssertEqual(valuesByKey["password"], "password")

        XCTAssertEqual(valuesByKey["captchaResponse"], "captchaToken")
    }

    /// `values` doesn't contain the captcha token if it's `nil`.
    func test_values_withoutCaptcha() {
        let subject = IdentityTokenRequestModel(
            authenticationMethod: .password(username: "user@example.com", password: "password"),
            captchaToken: nil,
            deviceInfo: .fixture()
        )
        let valuesByKey = valuesByKey(subject.values)

        XCTAssertNil(valuesByKey["captchaResponse"])
    }

    // MARK: Private

    /// Converts the list of `URLQueryItem`s to a dictionary keyed by the item's name.
    ///
    /// - Parameter values: The list of `URLQueryItem`s to convert.
    /// - Returns: A dictionary of items keyed by the item's name.
    ///
    private func valuesByKey(_ values: [URLQueryItem]) -> [String: String] {
        values.reduce(into: [String: String]()) { $0[$1.name] = $1.value }
    }
}
