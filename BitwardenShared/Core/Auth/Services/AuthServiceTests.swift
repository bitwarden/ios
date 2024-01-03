import XCTest

@testable import BitwardenShared

// MARK: - AuthServiceTests

class AuthServiceTests: BitwardenTestCase {
    // MARK: Properties

    var appSettingsStore: MockAppSettingsStore!
    var authAPIService: AuthAPIService!
    var client: MockHTTPClient!
    var clientGenerators: MockClientGenerators!
    var environmentService: MockEnvironmentService!
    var stateService: MockStateService!
    var subject: DefaultAuthService!
    var systemDevice: MockSystemDevice!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        appSettingsStore = MockAppSettingsStore()
        client = MockHTTPClient()
        authAPIService = APIService(client: client)
        clientGenerators = MockClientGenerators()
        environmentService = MockEnvironmentService()
        stateService = MockStateService()
        systemDevice = MockSystemDevice()

        subject = DefaultAuthService(
            appIdService: AppIdService(appSettingStore: appSettingsStore),
            authAPIService: authAPIService,
            clientGenerators: clientGenerators,
            environmentService: environmentService,
            stateService: stateService,
            systemDevice: systemDevice
        )
    }

    override func tearDown() {
        super.tearDown()

        appSettingsStore = nil
        authAPIService = nil
        client = nil
        clientGenerators = nil
        environmentService = nil
        stateService = nil
        subject = nil
        systemDevice = nil
    }

    // MARK: Tests

    /// `callbackUrlScheme` has the expected value.
    func test_callbackUrlScheme() {
        XCTAssertEqual(subject.callbackUrlScheme, "bitwarden")
    }

    /// `generateSingleSignOnUrl(from:)` generates the expected url.
    func test_generateSingleSignOnUrl() async throws {
        // Set up the mock data.
        client.result = .httpSuccess(testData: .preValidateSingleSignOn)

        // Generate the url.
        let result = try await subject.generateSingleSignOnUrl(from: "TeamLivefront")

        // Compare to the expected url.
        var expectedUrlComponents = URLComponents(string: "https://example.com/identity/connect/authorize")
        expectedUrlComponents?.queryItems = [
            URLQueryItem(name: "client_id", value: "mobile"),
            URLQueryItem(name: "redirect_uri", value: "bitwarden://sso-callback"),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: "api offline_access"),
            URLQueryItem(name: "state", value: "PASSWORD"),
            URLQueryItem(name: "code_challenge", value: "C-ZK6J3dJOIlQ03pXVAXETObru4Y8Am6m0NpryfTDWA"),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "response_mode", value: "query"),
            URLQueryItem(name: "domain_hint", value: "TeamLivefront"),
            URLQueryItem(name: "ssoToken", value: "BWUserPrefix_longincomprehensiblegibberishhere"),
        ]
        XCTAssertEqual(expectedUrlComponents?.url, result.0)
        XCTAssertEqual("PASSWORD", result.1)
    }

    /// `loginSingleSignOn(code:)` returns an account if the vault is still locked after authenticating.
    func test_loginSingleSignOn_success_vaultLocked() async throws {
        // Set up the mock data.
        appSettingsStore.appId = "App id"
        client.result = .httpSuccess(testData: .identityTokenSuccess)
        stateService.preAuthEnvironmentUrls = EnvironmentUrlData(base: URL(string: "https://vault.bitwarden.com"))
        systemDevice.modelIdentifier = "Model id"

        // Attempt to login.
        let account = try await subject.loginSingleSignOn(code: "super_cool_secret_code")

        // Verify the results.
        let tokenRequest = IdentityTokenRequestModel(
            authenticationMethod: .authorizationCode(
                code: "super_cool_secret_code",
                codeVerifier: "",
                redirectUri: "bitwarden://sso-callback"
            ),
            captchaToken: nil,
            deviceInfo: DeviceInfo(
                identifier: "App id",
                name: "Model id"
            )
        )
        XCTAssertEqual(client.requests.count, 1)
        XCTAssertEqual(client.requests[0].body, try tokenRequest.encode())

        XCTAssertEqual(stateService.accountsAdded, [.fixtureAccountLogin()])
        XCTAssertEqual(
            stateService.accountEncryptionKeys,
            [
                "13512467-9cfe-43b0-969f-07534084764b": AccountEncryptionKeys(
                    encryptedPrivateKey: "PRIVATE_KEY",
                    encryptedUserKey: "KEY"
                ),
            ]
        )

        XCTAssertEqual(account, .fixtureAccountLogin())
    }
}
