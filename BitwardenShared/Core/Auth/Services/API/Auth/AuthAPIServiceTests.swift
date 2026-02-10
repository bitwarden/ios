import TestHelpers
import XCTest

@testable import BitwardenShared
@testable import BitwardenSharedMocks

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
                requestApproved: true,
            ),
        )

        XCTAssertEqual(response, .fixture())
    }

    /// `checkPendingLoginRequest(withId:accessCode:)` successfully decodes the login request response.
    func test_checkPendingLoginRequest() async throws {
        client.result = .httpSuccess(testData: .authRequestSuccess)

        let response = try await subject.checkPendingLoginRequest(withId: "10", accessCode: "no")

        XCTAssertEqual(response, .fixture())
    }

    /// `getIdentityToken()` successfully decodes the identity token response.
    func test_getIdentityToken() async throws {
        client.result = .httpSuccess(testData: .identityTokenSuccess)

        let response = try await subject.getIdentityToken(
            IdentityTokenRequestModel(
                authenticationMethod: .password(username: "username", password: "password"),
                deviceInfo: .fixture(),
                loginRequestId: nil,
            ),
        )

        XCTAssertEqual(
            response,
            IdentityTokenResponseModel.fixture(),
        )
    }

    /// `getIdentityToken()` throws a `.newDeviceNotVerified` error when a `400` http response with the correct data
    /// is returned.
    func test_getIdentityToken_newDeviceNotVerified() async throws {
        client.result = .httpFailure(
            statusCode: 400,
            data: APITestData.identityTokenNewDeviceError.data,
        )

        await assertAsyncThrows(error: IdentityTokenRequestError.newDeviceNotVerified) {
            _ = try await subject.getIdentityToken(
                IdentityTokenRequestModel(
                    authenticationMethod: .password(username: "username", password: "password"),
                    deviceInfo: .fixture(),
                    loginRequestId: nil,
                ),
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

    /// `getWebAuthnCredentialAssertionOptions(_:)` successfully decodes the assertion options response.
    func test_getWebAuthnCredentialAssertionOptions() async throws {
        client.result = .httpSuccess(testData: .webAuthnLoginCredentialAssertionOptions)

        let response = try await subject.getWebAuthnCredentialAssertionOptions(
            SecretVerificationRequestModel(type: .masterPasswordHash("PASSWORD_HASH")),
        )

        XCTAssertEqual(response.options.challenge, "YXNzZXJ0aW9uLWNoYWxsZW5nZQ==")
        XCTAssertEqual(response.options.rpId, "example.com")
        XCTAssertEqual(response.options.timeout, 60000)
        XCTAssertEqual(response.options.allowCredentials?.first?.id, "Y3JlZGVudGlhbC0x")
        XCTAssertEqual(response.options.allowCredentials?.first?.type, "public-key")
        XCTAssertEqual(response.options.extensions?.prf?.eval?.first, "cHJmLWZpcnN0")
        XCTAssertNil(response.options.extensions?.prf?.eval?.second)
        XCTAssertEqual(
            response.options.extensions?.prf?.evalByCredential?["Y3JlZGVudGlhbC0x"]?.first,
            "Y3JlZC1wcmYtZmlyc3Q=",
        )
        XCTAssertEqual(
            response.options.extensions?.prf?.evalByCredential?["Y3JlZGVudGlhbC0x"]?.second,
            "Y3JlZC1wcmYtc2Vjb25k",
        )
    }

    /// `getWebAuthnCredentialCreationOptions(_:)` successfully decodes the creation options response.
    func test_getWebAuthnCredentialCreationOptions() async throws {
        client.result = .httpSuccess(testData: .webAuthnLoginCredentialCreationOptions)

        let response = try await subject.getWebAuthnCredentialCreationOptions(
            SecretVerificationRequestModel(type: .masterPasswordHash("PASSWORD_HASH")),
        )

        XCTAssertEqual(response.options.challenge, "dGVzdC1jaGFsbGVuZ2U=")
        XCTAssertEqual(response.options.rp.id, "example.com")
        XCTAssertEqual(response.options.rp.name, "Example RP")
        XCTAssertEqual(response.options.user.id, "dXNlci0xMjM=")
        XCTAssertEqual(response.options.user.name, "user@example.com")
        XCTAssertEqual(response.options.timeout, 60000)
        XCTAssertEqual(response.options.pubKeyCredParams.count, 2)
        XCTAssertEqual(response.options.pubKeyCredParams[0].alg, -7)
        XCTAssertEqual(response.options.pubKeyCredParams[0].type, "public-key")
        XCTAssertEqual(response.options.pubKeyCredParams[1].alg, -257)
        XCTAssertEqual(response.options.excludeCredentials?.first?.id, "Y3JlZGVudGlhbC0x")
        XCTAssertEqual(response.options.extensions?.prf?.eval?.first, "cHJmLWZpcnN0")
        XCTAssertEqual(response.options.extensions?.prf?.eval?.second, "cHJmLXNlY29uZA==")
    }

    /// `initiateLoginWithDevice()` successfully decodes the initiate login with device response.
    func test_initiateLoginWithDevice() async throws {
        client.result = .httpSuccess(testData: .authRequestSuccess)

        let response = try await subject.initiateLoginWithDevice(LoginWithDeviceRequestModel(
            email: "",
            publicKey: "",
            deviceIdentifier: "",
            accessCode: "",
            type: AuthRequestType.authenticateAndUnlock,
            fingerprintPhrase: "",
        ))

        XCTAssertEqual(response, .fixture())
    }

    /// `preValidateSingleSignOn(organizationIdentifier:)` successfully decodes the pre-validate
    ///  single sign on response.
    func test_preValidateSingleSignOn() async throws {
        client.result = .httpSuccess(testData: .preValidateSingleSignOn)

        let response = try await subject.preValidateSingleSignOn(organizationIdentifier: "TeamLivefront")

        XCTAssertEqual(
            response,
            PreValidateSingleSignOnResponse(token: "BWUserPrefix_longincomprehensiblegibberishhere"),
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
                refreshToken: "REFRESH_TOKEN",
            ),
        )
    }

    /// `saveWebAuthnCredential(_:)` sends the save request without error.
    func test_saveWebAuthnCredential() async throws {
        client.result = .httpSuccess(testData: .emptyResponse)

        await assertAsyncDoesNotThrow {
            try await subject.saveWebAuthnCredential(
                WebAuthnLoginSaveCredentialRequestModel(
                    deviceResponse: .fixture(),
                    encryptedPrivateKey: nil,
                    encryptedPublicKey: nil,
                    encryptedUserKey: nil,
                    name: "My Passkey",
                    supportsPrf: false,
                    token: "TOKEN",
                ),
            )
        }

        let request = try XCTUnwrap(client.requests.first)
        XCTAssertEqual(request.method, .post)
        XCTAssertEqual(request.url.relativePath, "/api/webauthn")
    }
}
