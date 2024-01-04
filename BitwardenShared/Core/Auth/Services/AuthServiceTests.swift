import XCTest

@testable import BitwardenShared

// MARK: - AuthServiceTests

class AuthServiceTests: BitwardenTestCase {
    // MARK: Properties

    var accountAPIService: AccountAPIService!
    var appSettingsStore: MockAppSettingsStore!
    var authAPIService: AuthAPIService!
    var client: MockHTTPClient!
    var clientAuth: MockClientAuth!
    var clientGenerators: MockClientGenerators!
    var environmentService: MockEnvironmentService!
    var stateService: MockStateService!
    var subject: DefaultAuthService!
    var systemDevice: MockSystemDevice!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        client = MockHTTPClient()
        accountAPIService = APIService(client: client)
        appSettingsStore = MockAppSettingsStore()
        authAPIService = APIService(client: client)
        clientAuth = MockClientAuth()
        clientGenerators = MockClientGenerators()
        environmentService = MockEnvironmentService()
        stateService = MockStateService()
        systemDevice = MockSystemDevice()

        subject = DefaultAuthService(
            accountAPIService: accountAPIService,
            appIdService: AppIdService(appSettingStore: appSettingsStore),
            authAPIService: authAPIService,
            clientAuth: clientAuth,
            clientGenerators: clientGenerators,
            environmentService: environmentService,
            stateService: stateService,
            systemDevice: systemDevice
        )
    }

    override func tearDown() {
        super.tearDown()

        accountAPIService = nil
        appSettingsStore = nil
        authAPIService = nil
        client = nil
        clientAuth = nil
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

    /// `loginWithMasterPassword(_:username:captchaToken:)` logs in with the password.
    func test_loginWithMasterPassword() async throws {
        // Set up the mock data.
        client.results = [
            .httpSuccess(testData: .preLoginSuccess),
            .httpSuccess(testData: .identityTokenSuccess),
        ]
        appSettingsStore.appId = "App id"
        clientAuth.hashPasswordResult = .success("hashed password")
        stateService.preAuthEnvironmentUrls = EnvironmentUrlData(base: URL(string: "https://vault.bitwarden.com"))
        systemDevice.modelIdentifier = "Model id"

        // Attempt to login.
        try await subject.loginWithMasterPassword(
            "Password1234!",
            username: "email@example.com",
            captchaToken: nil
        )

        // Verify the results.
        let preLoginRequest = PreLoginRequestModel(
            email: "email@example.com"
        )
        let tokenRequest = IdentityTokenRequestModel(
            authenticationMethod: .password(
                username: "email@example.com",
                password: "hashed password"
            ),
            captchaToken: nil,
            deviceInfo: DeviceInfo(
                identifier: "App id",
                name: "Model id"
            )
        )
        XCTAssertEqual(client.requests.count, 2)
        XCTAssertEqual(client.requests[0].body, try preLoginRequest.encode())
        XCTAssertEqual(client.requests[1].body, try tokenRequest.encode())

        XCTAssertEqual(clientAuth.hashPasswordEmail, "email@example.com")
        XCTAssertEqual(clientAuth.hashPasswordPassword, "Password1234!")
        XCTAssertEqual(clientAuth.hashPasswordKdfParams, .pbkdf2(iterations: 600_000))

        XCTAssertEqual(stateService.accountsAdded, [Account.fixtureAccountLogin()])
        XCTAssertEqual(
            stateService.accountEncryptionKeys,
            [
                "13512467-9cfe-43b0-969f-07534084764b": AccountEncryptionKeys(
                    encryptedPrivateKey: "PRIVATE_KEY",
                    encryptedUserKey: "KEY"
                ),
            ]
        )
        XCTAssertEqual(
            stateService.masterPasswordHashes,
            ["13512467-9cfe-43b0-969f-07534084764b": "hashed password"]
        )
    }

    /// `loginWithSingleSignOn(code:)` returns an account if the vault is still locked after authenticating.
    func test_loginSingleSignOn_vaultLocked() async throws {
        // Set up the mock data.
        appSettingsStore.appId = "App id"
        client.result = .httpSuccess(testData: .identityTokenSuccess)
        stateService.preAuthEnvironmentUrls = EnvironmentUrlData(base: URL(string: "https://vault.bitwarden.com"))
        systemDevice.modelIdentifier = "Model id"

        // Attempt to login.
        let account = try await subject.loginWithSingleSignOn(code: "super_cool_secret_code")

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
