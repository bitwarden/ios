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

    /// `getIdentityToken()` successfully decodes the identity token response.
    func test_getIdentityToken() async throws {
        client.result = .httpSuccess(testData: .identityTokenSuccess)

        let response = try await subject.getIdentityToken(
            IdentityTokenRequestModel(
                authenticationMethod: .password(username: "username", password: "password"),
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
                    authenticationMethod: .password(username: "username", password: "password"),
                    captchaToken: nil,
                    deviceInfo: .fixture()
                )
            )
        }
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
