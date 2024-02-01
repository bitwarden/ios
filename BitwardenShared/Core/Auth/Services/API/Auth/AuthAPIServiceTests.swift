import XCTest

@testable import BitwardenShared

class AuthAPIServiceTests: BitwardenTestCase {
    // MARK: Properties

    var client: MockHTTPClient!
    var subject: APIService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        client = MockHTTPClient()

        subject = APIService(client: client)
    }

    override func tearDown() {
        super.tearDown()

        client = nil
        subject = nil
    }

    // MARK: Tests

    /// `answerLoginRequest(_:requestModel:)` successfully decodes the answer login request response.
    func test_answerLoginRequest() async throws {
        client.result = .httpSuccess(testData: .authRequestSuccess)

        let response = try await subject.answerLoginRequest(
            "1",
            requestModel: .init(
                deviceIdentifier: "2",
                key: "key",
                masterPasswordHash: nil,
                requestApproved: true
            )
        )

        XCTAssertEqual(response, .fixture())
    }

    /// `getIdentityToken()` successfully decodes the identity token response.
    func test_getIdentityToken() async throws {
        client.result = .httpSuccess(testData: .identityTokenSuccess)

        let response = try await subject.getIdentityToken(
            IdentityTokenRequestModel(
                authenticationMethod: .password(
                    username: "username",
                    password: "password",
                    plainPassword: "plain password"
                ),
                captchaToken: nil,
                deviceInfo: .fixture()
            )
        )

        XCTAssertEqual(
            response,
            IdentityTokenResponseModel.fixture()
        )
    }

    /// `getIdentityToken()` throws a `.captchaRequired` error when a `400` http response with the correct data
    /// is returned.
    func test_getIdentityToken_captchaError() async throws {
        client.result = .httpFailure(
            statusCode: 400,
            data: APITestData.identityTokenCaptchaError.data
        )

        await assertAsyncThrows(error: IdentityTokenRequestError.captchaRequired(hCaptchaSiteCode: "1234")) {
            _ = try await subject.getIdentityToken(
                IdentityTokenRequestModel(
                    authenticationMethod: .password(
                        username: "username",
                        password: "password",
                        plainPassword: "plain password"
                    ),
                    captchaToken: nil,
                    deviceInfo: .fixture()
                )
            )
        }
    }

    /// `getPendingLoginRequest(withId:)` successfully decodes the pending login request response.
    func test_getPendingLoginRequest() async throws {
        client.result = .httpSuccess(testData: .authRequestSuccess)

        let response = try await subject.getPendingLoginRequest(withId: "10")

        XCTAssertEqual(response, .fixture())
    }

    /// `getPendingLoginRequests()` successfully decodes the pending login requests response.
    func test_getPendingLoginRequests() async throws {
        client.result = .httpSuccess(testData: .authRequestsSuccess)

        let response = try await subject.getPendingLoginRequests()

        XCTAssertEqual(response, [.fixture()])
    }

    /// `getSingleSignOnDetails(email:)` successfully decodes the single sign on details response.
    func test_getSingleSignOnDetails() async throws {
        client.result = .httpSuccess(testData: .singleSignOnDetails)

        let response = try await subject.getSingleSignOnDetails(email: "example@email.com")

        XCTAssertEqual(
            response,
            SingleSignOnDetailsResponse(organizationIdentifier: "TeamLivefront", ssoAvailable: true)
        )
    }

    /// `initiateLoginWithDevice()` successfully decodes the initiate login with device response.
    func test_initiateLoginWithDevice() async throws {
        client.result = .httpSuccess(testData: .authRequestSuccess)

        let response = try await subject.initiateLoginWithDevice(
            accessCode: "",
            deviceIdentifier: "",
            email: "",
            fingerPrint: "",
            publicKey: ""
        )

        XCTAssertEqual(response, .fixture())
    }

    /// `preValidateSingleSignOn(organizationIdentifier:)` successfully decodes the pre-validate
    ///  single sign on response.
    func test_preValidateSingleSignOn() async throws {
        client.result = .httpSuccess(testData: .preValidateSingleSignOn)

        let response = try await subject.preValidateSingleSignOn(organizationIdentifier: "TeamLivefront")

        XCTAssertEqual(
            response,
            PreValidateSingleSignOnResponse(token: "BWUserPrefix_longincomprehensiblegibberishhere")
        )
    }

    /// `refreshIdentityToken()` successfully decodes the identity token refresh response.
    func test_refreshIdentityToken() async throws {
        client.result = .httpSuccess(testData: .identityTokenRefresh)

        let response = try await subject.refreshIdentityToken(refreshToken: "REFRESH_TOKEN")

        XCTAssertEqual(
            response,
            IdentityTokenRefreshResponseModel(
                accessToken: "ACCESS_TOKEN",
                expiresIn: 3600,
                tokenType: "Bearer",
                refreshToken: "REFRESH_TOKEN"
            )
        )
    }
}
