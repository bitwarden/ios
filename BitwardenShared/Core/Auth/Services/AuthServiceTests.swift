import BitwardenKit
import BitwardenKitMocks
import BitwardenSdk
import TestHelpers
import XCTest

@testable import BitwardenShared

// MARK: - AuthServiceTests

class AuthServiceTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: Properties

    var accountAPIService: AccountAPIService!
    var appSettingsStore: MockAppSettingsStore!
    var authAPIService: AuthAPIService!
    var client: MockHTTPClient!
    var clientService: MockClientService!
    var configService: MockConfigService!
    var credentialIdentityStore: MockCredentialIdentityStore!
    var environmentService: MockEnvironmentService!
    var errorReporter: MockErrorReporter!
    var keychainRepository: MockKeychainRepository!
    var stateService: MockStateService!
    var policyService: MockPolicyService!
    var subject: DefaultAuthService!
    var systemDevice: MockSystemDevice!
    var trustDeviceService: MockTrustDeviceService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        client = MockHTTPClient()
        accountAPIService = APIService(client: client)
        appSettingsStore = MockAppSettingsStore()
        authAPIService = APIService(client: client)
        clientService = MockClientService()
        configService = MockConfigService()
        configService.configMocker
            .withResult(ServerConfig(
                date: Date(year: 2024, month: 2, day: 14, hour: 7, minute: 50, second: 0),
                responseModel: ConfigResponseModel(
                    environment: nil,
                    featureStates: [:],
                    gitHash: "75238191",
                    server: nil,
                    version: "2024.6.0"
                )
            ))
        credentialIdentityStore = MockCredentialIdentityStore()
        environmentService = MockEnvironmentService()
        errorReporter = MockErrorReporter()
        keychainRepository = MockKeychainRepository()
        policyService = MockPolicyService()
        stateService = MockStateService()
        systemDevice = MockSystemDevice()
        trustDeviceService = MockTrustDeviceService()

        subject = DefaultAuthService(
            accountAPIService: accountAPIService,
            appIdService: AppIdService(appSettingStore: appSettingsStore),
            authAPIService: authAPIService,
            clientService: clientService,
            configService: configService,
            credentialIdentityStore: credentialIdentityStore,
            environmentService: environmentService,
            errorReporter: errorReporter,
            keychainRepository: keychainRepository,
            policyService: policyService,
            stateService: stateService,
            systemDevice: systemDevice,
            trustDeviceService: trustDeviceService
        )
    }

    override func tearDown() {
        super.tearDown()

        accountAPIService = nil
        appSettingsStore = nil
        authAPIService = nil
        client = nil
        clientService = nil
        configService = nil
        credentialIdentityStore = nil
        environmentService = nil
        errorReporter = nil
        keychainRepository = nil
        stateService = nil
        subject = nil
        systemDevice = nil
    }

    // MARK: Tests

    /// `answerLoginRequest(_:approve:)` encrypts the key and answers the login request.
    func test_answerLoginRequest() async throws {
        // Set up the mock data.
        client.result = .httpSuccess(testData: .authRequestSuccess)
        stateService.activeAccount = .fixture()
        appSettingsStore.appId = "App id"

        // Test.
        try await subject.answerLoginRequest(.fixture(), approve: true)

        // Confirm the results.
        XCTAssertEqual(clientService.mockAuth.approveAuthRequestPublicKey, "reallyLongPublicKey")
        XCTAssertEqual(client.requests.last?.url.absoluteString, "https://example.com/api/auth-requests/1")
    }

    /// `callbackUrlScheme` has the expected value.
    func test_callbackUrlScheme() {
        XCTAssertEqual(subject.callbackUrlScheme, "bitwarden")
    }

    /// `checkPendingLoginRequest(withId:)` returns the result of the API request.
    func test_checkPendingLoginRequest() async throws {
        // First initiate the login with device flow so that the necessary data is cached.
        client.results = [
            .httpSuccess(testData: .authRequestSuccess),
            .httpSuccess(testData: .authRequestSuccess),
        ]
        appSettingsStore.appId = "App id"
        clientService.mockAuth.newAuthRequestResult = .success(.init(
            privateKey: "",
            publicKey: "",
            fingerprint: "fingerprint",
            accessCode: "accessCode"
        ))
        let request = try await subject.initiateLoginWithDevice(
            email: "email@example.com",
            type: AuthRequestType.authenticateAndUnlock
        )

        // Check the pending login request.
        let updatedRequest = try await subject.checkPendingLoginRequest(withId: request.requestId)

        XCTAssertEqual(updatedRequest, .fixture())
        XCTAssertEqual(
            client.requests.last?.url.absoluteString,
            "https://example.com/api/auth-requests/1/response?code=accessCode"
        )
    }

    /// `checkPendingLoginRequest(withId:)` throws an error if there's no cached data.
    func test_checkPendingLoginRequest_error() async throws {
        await assertAsyncThrows(error: AuthError.missingLoginWithDeviceData) {
            _ = try await subject.checkPendingLoginRequest(withId: "404")
        }
    }

    /// `denyAllLoginRequests(_:)` denies all the login requests.
    func test_denyAllLoginRequests() async throws {
        // Set up the mock data.
        client.result = .httpSuccess(testData: .authRequestSuccess)
        stateService.activeAccount = .fixture()
        appSettingsStore.appId = "App id"

        // Test.
        try await subject.denyAllLoginRequests([.fixture()])

        // Confirm the results.
        XCTAssertEqual(clientService.mockAuth.approveAuthRequestPublicKey, "reallyLongPublicKey")
        XCTAssertEqual(client.requests.last?.url.absoluteString, "https://example.com/api/auth-requests/1")
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

    /// `getPendingAdminLoginRequest(userId:)` returns the specific admin pending login request.
    func test_getPendingAdminLoginRequest() async throws {
        stateService.activeAccount = .fixture()
        let keychainRequest = try JSONEncoder().encode(PendingAdminLoginRequest.fixture())
        keychainRepository.getPendingAdminLoginRequestResult = .success(String(data: keychainRequest, encoding: .utf8)!)

        let result = try await subject.getPendingAdminLoginRequest(userId: "1")
        XCTAssertEqual(result, .fixture())
    }

    /// setPendingAdminLoginRequest()` sets the specific pending login request.
    func test_setPendingAdminLoginRequest_value() async throws {
        stateService.activeAccount = .fixture()
        keychainRepository.setPendingAdminLoginRequestResult = .success(())

        try await subject.setPendingAdminLoginRequest(PendingAdminLoginRequest.fixture(), userId: "1")

        let jsonData = keychainRepository.mockStorage[
            keychainRepository.formattedKey(for: .pendingAdminLoginRequest(userId: "1"))
        ]!.data(using: .utf8)!
        let request = try JSONDecoder().decode(PendingAdminLoginRequest.self, from: jsonData)
        XCTAssertEqual(
            request,
            PendingAdminLoginRequest.fixture()
        )
    }

    /// setPendingAdminLoginRequest()` deletes the specific pending login request.
    func test_setPendingAdminLoginRequest_nil() async throws {
        stateService.activeAccount = .fixture()
        let keychainRequest = try JSONEncoder().encode(PendingAdminLoginRequest.fixture())
        keychainRepository.setPendingAdminLoginRequestResult = .success(())
        keychainRepository.mockStorage[
            keychainRepository.formattedKey(for: .pendingAdminLoginRequest(userId: "1"))
        ] = String(data: keychainRequest, encoding: .utf8)!

        try await subject.setPendingAdminLoginRequest(nil, userId: "1")

        XCTAssertEqual(
            keychainRepository.mockStorage[
                keychainRepository.formattedKey(for: .pendingAdminLoginRequest(userId: "1"))
            ],
            nil
        )
    }

    /// `getPendingLoginRequests(withId:)` returns the specific pending login request.
    func test_getPendingLoginRequest() async throws {
        stateService.activeAccount = .fixture()
        client.result = .httpSuccess(testData: .authRequestSuccess)

        let result = try await subject.getPendingLoginRequest(withId: "1")

        XCTAssertEqual(result, [.fixture(fingerprintPhrase: "a-fingerprint-phrase-string-placeholder")])
    }

    /// `getPendingLoginRequests()` returns all the active pending login requests.
    func test_getPendingLoginRequests() async throws {
        stateService.activeAccount = .fixture()
        client.result = .httpSuccess(testData: .authRequestsSuccess)

        let result = try await subject.getPendingLoginRequests()

        XCTAssertEqual(result, [.fixture(fingerprintPhrase: "a-fingerprint-phrase-string-placeholder")])
    }

    /// `initiateLoginWithDevice(email:)` calls the sdk method and returns a fingerprint.
    func test_initiateLoginWithDevice() async throws {
        // Set up the mock data.
        client.result = .httpSuccess(testData: .authRequestSuccess)
        appSettingsStore.appId = "App id"
        let authRequestResponse = AuthRequestResponse.fixture()
        clientService.mockAuth.newAuthRequestResult = .success(authRequestResponse)

        // Test.
        let result = try await subject.initiateLoginWithDevice(
            email: "email@example.com",
            type: AuthRequestType.authenticateAndUnlock
        )

        // Verify the results.
        XCTAssertEqual(client.requests.count, 1)
        XCTAssertEqual(clientService.mockAuth.newAuthRequestEmail, "email@example.com")
        XCTAssertTrue(clientService.mockAuthIsPreAuth)
        XCTAssertEqual(result.authRequestResponse, authRequestResponse)
        XCTAssertEqual(result.requestId, LoginRequest.fixture().id)
    }

    /// `loginWithDevice(_:email:captchaToken:)` logs in with an approved login with device request.
    func test_loginWithDevice() async throws {
        // First initiate the login with device flow so that the necessary data is cached.
        client.results = [
            .httpSuccess(testData: .authRequestSuccess),
            .httpSuccess(testData: .identityTokenSuccess),
        ]
        appSettingsStore.appId = "App id"
        systemDevice.modelIdentifier = "Model id"
        clientService.mockAuth.newAuthRequestResult = .success(.init(
            privateKey: "",
            publicKey: "",
            fingerprint: "fingerprint",
            accessCode: "accessCode"
        ))
        _ = try await subject.initiateLoginWithDevice(
            email: "email@example.com",
            type: AuthRequestType.authenticateAndUnlock
        )

        // Attempt to log in.
        _ = try await subject.loginWithDevice(.fixture(), email: "email@example.com", captchaToken: nil)

        // Verify the results.
        let tokenRequest = IdentityTokenRequestModel(
            authenticationMethod: .password(
                username: "email@example.com",
                password: "accessCode"
            ),
            captchaToken: nil,
            deviceInfo: DeviceInfo(
                identifier: "App id",
                name: "Model id"
            ),
            loginRequestId: "1"
        )
        XCTAssertEqual(client.requests.last?.body, try tokenRequest.encode())
        await assertGetConfig()
    }

    /// `loginWithDevice(_:email:captchaToken:)` throws an error if there's no cached data.
    func test_loginWithDevice_error() async throws {
        await assertAsyncThrows(error: AuthError.missingLoginWithDeviceData) {
            _ = try await subject.loginWithDevice(.fixture(), email: "", captchaToken: nil)
        }
    }

    /// `loginWithMasterPassword(_:username:captchaToken:)` logs in with the password.
    @MainActor
    func test_loginWithMasterPassword() async throws { // swiftlint:disable:this function_body_length
        // Set up the mock data.
        client.results = [
            .httpSuccess(testData: .preLoginSuccess),
            .httpSuccess(testData: .identityTokenSuccess),
        ]
        appSettingsStore.appId = "App id"
        clientService.mockAuth.hashPasswordResult = .success("hashed password")
        stateService.preAuthEnvironmentURLs = EnvironmentURLData(base: URL(string: "https://vault.bitwarden.com"))
        systemDevice.modelIdentifier = "Model id"

        // Attempt to login.
        try await subject.loginWithMasterPassword(
            "Password1234!",
            username: "email@example.com",
            captchaToken: nil,
            isNewAccount: false
        )

        // Verify the results.
        let preLoginRequest = PreLoginRequestModel(
            email: "email@example.com"
        )
        let tokenRequest = IdentityTokenRequestModel(
            authenticationMethod: .password(username: "email@example.com", password: "hashed password"),
            captchaToken: nil,
            deviceInfo: DeviceInfo(
                identifier: "App id",
                name: "Model id"
            ),
            loginRequestId: nil
        )
        XCTAssertEqual(client.requests.count, 2)
        XCTAssertEqual(client.requests[0].body, try preLoginRequest.encode())
        XCTAssertEqual(client.requests[1].body, try tokenRequest.encode())

        XCTAssertEqual(clientService.mockAuth.hashPasswordEmail, "user@bitwarden.com")
        XCTAssertEqual(clientService.mockAuth.hashPasswordPassword, "Password1234!")
        XCTAssertEqual(clientService.mockAuth.hashPasswordKdfParams, .pbkdf2(iterations: 600_000))

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
        XCTAssertNil(stateService.accountSetupAutofill["13512467-9cfe-43b0-969f-07534084764b"])
        XCTAssertNil(stateService.accountSetupImportLogins["13512467-9cfe-43b0-969f-07534084764b"])
        XCTAssertNil(stateService.accountSetupVaultUnlock["13512467-9cfe-43b0-969f-07534084764b"])
        XCTAssertEqual(
            stateService.masterPasswordHashes,
            ["13512467-9cfe-43b0-969f-07534084764b": "hashed password"]
        )
        try XCTAssertEqual(
            keychainRepository.getValue(for: .accessToken(userId: "13512467-9cfe-43b0-969f-07534084764b")),
            IdentityTokenResponseModel.fixture().accessToken
        )
        try XCTAssertEqual(
            keychainRepository.getValue(for: .refreshToken(userId: "13512467-9cfe-43b0-969f-07534084764b")),
            IdentityTokenResponseModel.fixture().refreshToken
        )
        assertGetConfig()
    }

    /// `loginWithMasterPassword(_:username:captchaToken:)` logs the user in with the password for
    /// a newly created account.
    @MainActor
    func test_loginWithMasterPassword_isNewAccount() async throws { // swiftlint:disable:this function_body_length
        client.results = [
            .httpSuccess(testData: .preLoginSuccess),
            .httpSuccess(testData: .identityTokenSuccess),
        ]
        appSettingsStore.appId = "App id"
        clientService.mockAuth.hashPasswordResult = .success("hashed password")
        credentialIdentityStore.state.mockIsEnabled = false
        stateService.preAuthEnvironmentURLs = EnvironmentURLData(base: URL(string: "https://vault.bitwarden.com"))
        systemDevice.modelIdentifier = "Model id"

        // Attempt to login.
        try await subject.loginWithMasterPassword(
            "Password1234!",
            username: "email@example.com",
            captchaToken: nil,
            isNewAccount: true
        )

        // Verify the results.
        let preLoginRequest = PreLoginRequestModel(
            email: "email@example.com"
        )
        let tokenRequest = IdentityTokenRequestModel(
            authenticationMethod: .password(username: "email@example.com", password: "hashed password"),
            captchaToken: nil,
            deviceInfo: DeviceInfo(
                identifier: "App id",
                name: "Model id"
            ),
            loginRequestId: nil
        )
        XCTAssertEqual(client.requests.count, 2)
        XCTAssertEqual(client.requests[0].body, try preLoginRequest.encode())
        XCTAssertEqual(client.requests[1].body, try tokenRequest.encode())

        XCTAssertEqual(clientService.mockAuth.hashPasswordEmail, "user@bitwarden.com")
        XCTAssertEqual(clientService.mockAuth.hashPasswordPassword, "Password1234!")
        XCTAssertEqual(clientService.mockAuth.hashPasswordKdfParams, .pbkdf2(iterations: 600_000))

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
        XCTAssertEqual(stateService.accountSetupAutofill["13512467-9cfe-43b0-969f-07534084764b"], .incomplete)
        XCTAssertEqual(stateService.accountSetupImportLogins["13512467-9cfe-43b0-969f-07534084764b"], .incomplete)
        XCTAssertEqual(stateService.accountSetupVaultUnlock["13512467-9cfe-43b0-969f-07534084764b"], .incomplete)
        XCTAssertEqual(
            stateService.masterPasswordHashes,
            ["13512467-9cfe-43b0-969f-07534084764b": "hashed password"]
        )
        try XCTAssertEqual(
            keychainRepository.getValue(for: .accessToken(userId: "13512467-9cfe-43b0-969f-07534084764b")),
            IdentityTokenResponseModel.fixture().accessToken
        )
        try XCTAssertEqual(
            keychainRepository.getValue(for: .refreshToken(userId: "13512467-9cfe-43b0-969f-07534084764b")),
            IdentityTokenResponseModel.fixture().refreshToken
        )
        assertGetConfig()
    }

    /// `loginWithMasterPassword(_:username:captchaToken:)` logs the user in with the password for
    /// a newly created account and logs an error instead of throwing if setting the account setup
    /// progress fails.
    @MainActor
    func test_loginWithMasterPassword_isNewAccount_accountSetupError() async throws {
        client.results = [
            .httpSuccess(testData: .preLoginSuccess),
            .httpSuccess(testData: .identityTokenSuccess),
        ]
        appSettingsStore.appId = "App id"
        clientService.mockAuth.hashPasswordResult = .success("hashed password")
        credentialIdentityStore.state.mockIsEnabled = true
        stateService.accountSetupAutofillError = BitwardenTestError.example
        stateService.preAuthEnvironmentURLs = EnvironmentURLData(base: URL(string: "https://vault.bitwarden.com"))
        systemDevice.modelIdentifier = "Model id"

        // Attempt to login.
        try await subject.loginWithMasterPassword(
            "Password1234!",
            username: "email@example.com",
            captchaToken: nil,
            isNewAccount: true
        )

        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])

        XCTAssertNil(stateService.accountSetupAutofill["13512467-9cfe-43b0-969f-07534084764b"])
        XCTAssertNil(stateService.accountSetupImportLogins["13512467-9cfe-43b0-969f-07534084764b"])
        XCTAssertNil(stateService.accountSetupVaultUnlock["13512467-9cfe-43b0-969f-07534084764b"])
    }

    /// `loginWithMasterPassword(_:username:captchaToken:)` logs the user in with the password for
    /// a newly created account and sets their autofill account setup progress to complete if
    /// autofill is already enabled.
    @MainActor
    func test_loginWithMasterPassword_isNewAccount_autofillEnabled() async throws {
        client.results = [
            .httpSuccess(testData: .preLoginSuccess),
            .httpSuccess(testData: .identityTokenSuccess),
        ]
        appSettingsStore.appId = "App id"
        clientService.mockAuth.hashPasswordResult = .success("hashed password")
        credentialIdentityStore.state.mockIsEnabled = true
        stateService.preAuthEnvironmentURLs = EnvironmentURLData(base: URL(string: "https://vault.bitwarden.com"))
        systemDevice.modelIdentifier = "Model id"

        // Attempt to login.
        try await subject.loginWithMasterPassword(
            "Password1234!",
            username: "email@example.com",
            captchaToken: nil,
            isNewAccount: true
        )

        XCTAssertEqual(stateService.accountSetupAutofill["13512467-9cfe-43b0-969f-07534084764b"], .complete)
        XCTAssertEqual(stateService.accountSetupImportLogins["13512467-9cfe-43b0-969f-07534084764b"], .incomplete)
        XCTAssertEqual(stateService.accountSetupVaultUnlock["13512467-9cfe-43b0-969f-07534084764b"], .incomplete)
    }

    /// `loginWithMasterPassword(_:username:captchaToken:)` logs in with the password updates AccountProfile's
    /// `.forcePasswordResetReason` value if policy requires user to update password.
    @MainActor
    func test_loginWithMasterPassword_updatesAccountProfile() async throws {
        // Set up the mock data.
        client.results = [
            .httpSuccess(testData: .preLoginSuccess),
            .httpSuccess(testData: .identityTokenWithMasterPasswordPolicy),
        ]
        appSettingsStore.appId = "App id"
        clientService.mockAuth.hashPasswordResult = .success("hashed password")
        clientService.mockAuth.satisfiesPolicyResult = false
        stateService.preAuthEnvironmentURLs = EnvironmentURLData(base: URL(string: "https://vault.bitwarden.com"))
        systemDevice.modelIdentifier = "Model id"

        // Attempt to login.
        try await subject.loginWithMasterPassword(
            "Password1234!",
            username: "email@example.com",
            captchaToken: nil,
            isNewAccount: false
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
            ),
            loginRequestId: nil
        )
        XCTAssertEqual(client.requests.count, 2)
        XCTAssertEqual(client.requests[0].body, try preLoginRequest.encode())
        XCTAssertEqual(client.requests[1].body, try tokenRequest.encode())

        XCTAssertEqual(clientService.mockAuth.hashPasswordEmail, "user@bitwarden.com")
        XCTAssertEqual(clientService.mockAuth.hashPasswordPassword, "Password1234!")
        XCTAssertEqual(clientService.mockAuth.hashPasswordKdfParams, .pbkdf2(iterations: 600_000))

        XCTAssertEqual(
            stateService.forcePasswordResetReason["13512467-9cfe-43b0-969f-07534084764b"],
            .weakMasterPasswordOnLogin
        )
        assertGetConfig()
    }

    /// `loginWithMasterPassword(_:username:captchaToken:)` handles a two-factor auth error.
    func test_loginWithMasterPassword_twoFactorError() async throws {
        // Set up the mock data.
        client.results = [
            .httpSuccess(testData: .preLoginSuccess),
            .httpFailure(
                statusCode: 400,
                headers: [:],
                data: APITestData.identityTokenTwoFactorError.data
            ),
        ]
        appSettingsStore.appId = "App id"
        await stateService.setTwoFactorToken("some token", email: "email@example.com")
        clientService.mockAuth.hashPasswordResult = .success("hashed password")
        stateService.preAuthEnvironmentURLs = EnvironmentURLData(base: URL(string: "https://vault.bitwarden.com"))
        systemDevice.modelIdentifier = "Model id"

        // Attempt to login.
        let authMethodsData = AuthMethodsData.fixture()
        await assertAsyncThrows(
            error: IdentityTokenRequestError.twoFactorRequired(
                authMethodsData,
                "BWCaptchaBypass_ABCXYZ",
                nil,
                "exampleToken"
            )
        ) {
            try await subject.loginWithMasterPassword(
                "Password1234!",
                username: "email@example.com",
                captchaToken: nil,
                isNewAccount: false
            )
        }

        // Verify the results.
        let cachedToken = await stateService.getTwoFactorToken(email: "email@example.com")
        XCTAssertNil(cachedToken)
    }

    /// `loginWithSingleSignOn(code:email:)` returns the device key unlock method if the user
    /// uses trusted device encryption.
    func test_loginSingleSignOn_deviceKey() async throws {
        client.result = .httpSuccess(testData: .identityTokenTrustedDevice)

        let unlockMethod = try await subject.loginWithSingleSignOn(code: "super_cool_secret_code", email: "")

        XCTAssertEqual(unlockMethod, .deviceKey)
        await assertGetConfig()
    }

    /// `loginWithSingleSignOn(code:email:)` returns the key connector unlock method if the user
    /// uses key connector.
    func test_loginSingleSignOn_keyConnector() async throws {
        client.result = .httpSuccess(testData: .identityTokenKeyConnector)

        let unlockMethod = try await subject.loginWithSingleSignOn(code: "super_cool_secret_code", email: "")

        XCTAssertEqual(
            unlockMethod,
            .keyConnector(keyConnectorURL: URL(string: "https://vault.bitwarden.com/key-connector")!)
        )
        await assertGetConfig()
    }

    // `loginWithSingleSignOn(code:email:)` returns the master password unlock method if the user
    // could use key connector but still has a master password.
    func test_loginSingleSignOn_keyConnectorWithMasterPassword() async throws {
        client.result = .httpSuccess(testData: .identityTokenKeyConnectorMasterPassword)

        let unlockMethod = try await subject.loginWithSingleSignOn(code: "super_cool_secret_code", email: "")

        let response = try JSONDecoder.pascalOrSnakeCaseDecoder.decode(
            IdentityTokenResponseModel.self,
            from: APITestData.identityTokenKeyConnectorMasterPassword.data
        )
        let account = try Account(identityTokenResponseModel: response, environmentURLs: nil)

        XCTAssertEqual(
            unlockMethod,
            .masterPassword(account)
        )
        await assertGetConfig()
    }

    /// `loginWithSingleSignOn(code:email:)` throws an error if the user doesn't have a master password set.
    func test_loginSingleSignOn_noMasterPassword() async {
        client.result = .httpSuccess(testData: .identityTokenNoMasterPassword)

        await assertAsyncThrows(error: AuthError.requireSetPassword) {
            _ = try await subject.loginWithSingleSignOn(code: "super_cool_secret_code", email: "")
        }
        await assertGetConfig()
    }

    /// `loginWithSingleSignOn(code:email:)` returns an account if the vault is still locked after authenticating.
    func test_loginSingleSignOn_vaultLocked() async throws {
        // Set up the mock data.
        appSettingsStore.appId = "App id"
        client.result = .httpSuccess(testData: .identityTokenSuccess)
        stateService.preAuthEnvironmentURLs = EnvironmentURLData(base: URL(string: "https://vault.bitwarden.com"))
        systemDevice.modelIdentifier = "Model id"

        // Attempt to login.
        let unlockMethod = try await subject.loginWithSingleSignOn(code: "super_cool_secret_code", email: "")

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
            ),
            loginRequestId: nil
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
        try XCTAssertEqual(
            keychainRepository.getValue(for: .accessToken(userId: "13512467-9cfe-43b0-969f-07534084764b")),
            IdentityTokenResponseModel.fixture().accessToken
        )
        try XCTAssertEqual(
            keychainRepository.getValue(for: .refreshToken(userId: "13512467-9cfe-43b0-969f-07534084764b")),
            IdentityTokenResponseModel.fixture().refreshToken
        )

        XCTAssertEqual(unlockMethod, .masterPassword(.fixtureAccountLogin()))
        await assertGetConfig()
    }

    /// `loginWithTwoFactorCode(email:code:method:remember:captchaToken:)` uses the cached request but with two factor
    /// codes added in to authenticate.
    func test_loginWithTwoFactorCode() async throws { // swiftlint:disable:this function_body_length
        // Set up the mock data.
        client.results = [
            .httpSuccess(testData: .preLoginSuccess),
            .httpFailure(
                statusCode: 400,
                headers: [:],
                data: APITestData.identityTokenTwoFactorError.data
            ),
            .httpSuccess(testData: .identityTokenSuccessTwoFactorToken),
        ]
        appSettingsStore.appId = "App id"
        await stateService.setTwoFactorToken("some token", email: "email@example.com")
        clientService.mockAuth.hashPasswordResult = .success("hashed password")
        stateService.preAuthEnvironmentURLs = EnvironmentURLData(base: URL(string: "https://vault.bitwarden.com"))
        systemDevice.modelIdentifier = "Model id"

        // First login with the master password so that the request will be saved.
        let authMethodsData = AuthMethodsData.fixture()
        await assertAsyncThrows(
            error: IdentityTokenRequestError.twoFactorRequired(
                authMethodsData,
                "BWCaptchaBypass_ABCXYZ",
                nil,
                "exampleToken"
            )
        ) {
            try await subject.loginWithMasterPassword(
                "Password1234!",
                username: "email@example.com",
                captchaToken: nil,
                isNewAccount: false
            )
        }

        // Login with the two-factor code.
        let unlockMethod = try await subject.loginWithTwoFactorCode(
            email: "email@example.com",
            code: "just_a_lil_code",
            method: .email,
            remember: true
        )

        // Verify the results.
        let cachedToken = await stateService.getTwoFactorToken(email: "email@example.com")
        XCTAssertNotNil(cachedToken)

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
        XCTAssertEqual(
            stateService.masterPasswordHashes,
            ["13512467-9cfe-43b0-969f-07534084764b": "hashed password"]
        )
        try XCTAssertEqual(
            keychainRepository.getValue(for: .accessToken(userId: "13512467-9cfe-43b0-969f-07534084764b")),
            IdentityTokenResponseModel.fixture().accessToken
        )
        try XCTAssertEqual(
            keychainRepository.getValue(for: .refreshToken(userId: "13512467-9cfe-43b0-969f-07534084764b")),
            IdentityTokenResponseModel.fixture().refreshToken
        )

        XCTAssertEqual(unlockMethod, .masterPassword(.fixtureAccountLogin()))
        await assertGetConfig()
    }

    /// `loginWithTwoFactorCode(email:code:method:remember:captchaToken:)` uses the cached request
    /// but with device verification code added in to authenticate.
    func test_loginWithNewDeviceVerificationCode() async throws { // swiftlint:disable:this function_body_length
        // Set up the mock data.
        client.results = [
            .httpSuccess(testData: .preLoginSuccess),
            .httpFailure(
                statusCode: 400,
                headers: [:],
                data: APITestData.identityTokenNewDeviceError.data
            ),
            .httpSuccess(testData: .identityTokenSuccess),
        ]
        appSettingsStore.appId = "App id"
        await stateService.setTwoFactorToken("some token", email: "email@example.com")
        clientService.mockAuth.hashPasswordResult = .success("hashed password")
        stateService.preAuthEnvironmentURLs = EnvironmentURLData(base: URL(string: "https://vault.bitwarden.com"))
        systemDevice.modelIdentifier = "Model id"

        // First login with the master password so that the request will be saved.
        await assertAsyncThrows(
            error: IdentityTokenRequestError.newDeviceNotVerified
        ) {
            try await subject.loginWithMasterPassword(
                "Password1234!",
                username: "email@example.com",
                captchaToken: nil,
                isNewAccount: false
            )
        }

        // Login with the two-factor code.
        let unlockMethod = try await subject.loginWithTwoFactorCode(
            email: "email@example.com",
            code: "just_a_lil_code",
            method: .email,
            remember: true
        )

        // Verify the results.
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
        XCTAssertEqual(
            stateService.masterPasswordHashes,
            ["13512467-9cfe-43b0-969f-07534084764b": "hashed password"]
        )
        try XCTAssertEqual(
            keychainRepository.getValue(for: .accessToken(userId: "13512467-9cfe-43b0-969f-07534084764b")),
            IdentityTokenResponseModel.fixture().accessToken
        )
        try XCTAssertEqual(
            keychainRepository.getValue(for: .refreshToken(userId: "13512467-9cfe-43b0-969f-07534084764b")),
            IdentityTokenResponseModel.fixture().refreshToken
        )

        XCTAssertEqual(unlockMethod, .masterPassword(.fixtureAccountLogin()))
        await assertGetConfig()
    }

    /// `loginWithTwoFactorCode()` returns the device key unlock method if the user uses trusted
    /// device encryption.
    func test_loginWithTwoFactorCode_deviceKey() async throws {
        client.results = [
            .httpSuccess(testData: .preLoginSuccess),
            .httpFailure(
                statusCode: 400,
                headers: [:],
                data: APITestData.identityTokenTwoFactorError.data
            ),
            .httpSuccess(testData: .identityTokenTrustedDevice),
        ]

        // First login with the master password so that the request will be saved.
        let authMethodsData = AuthMethodsData.fixture()
        await assertAsyncThrows(
            error: IdentityTokenRequestError.twoFactorRequired(
                authMethodsData,
                "BWCaptchaBypass_ABCXYZ",
                nil,
                "exampleToken"
            )
        ) {
            try await subject.loginWithMasterPassword(
                "Password1234!",
                username: "email@example.com",
                captchaToken: nil,
                isNewAccount: false
            )
        }

        let unlockMethod = try await subject.loginWithTwoFactorCode(
            email: "email@example.com",
            code: "just_a_lil_code",
            method: .email,
            remember: true
        )
        XCTAssertEqual(unlockMethod, .deviceKey)
        await assertGetConfig()
    }

    /// `loginWithTwoFactorCode(email:code:method:remember:captchaToken:)` set forcePasswordResetReason as
    /// weakMasterPasswordOnLogin as master password doesn't fullfil org policies.
    func test_loginWithTwoFactorCode_forcePasswordResetReason() async throws { // swiftlint:disable:this function_body_length line_length
        // Set up the mock data.
        client.results = [
            .httpSuccess(testData: .preLoginSuccess),
            .httpFailure(
                statusCode: 400,
                headers: [:],
                data: APITestData.identityTokenTwoFactorError.data
            ),
            .httpSuccess(testData: .identityTokenSuccessTwoFactorToken),
        ]
        appSettingsStore.appId = "App id"
        await stateService.setTwoFactorToken("some token", email: "email@example.com")
        clientService.mockAuth.hashPasswordResult = .success("hashed password")
        stateService.preAuthEnvironmentURLs = EnvironmentURLData(base: URL(string: "https://vault.bitwarden.com"))
        systemDevice.modelIdentifier = "Model id"

        let policy = MasterPasswordPolicyOptions(
            minComplexity: 6,
            minLength: 6,
            requireUpper: true,
            requireLower: true,
            requireNumbers: true,
            requireSpecial: true,
            enforceOnLogin: true
        )
        clientService.mockAuth.satisfiesPolicyResult = false
        policyService.getMasterPasswordPolicyOptionsResult = .success(policy)

        // First login with the master password so that the request will be saved.
        let authMethodsData = AuthMethodsData.fixture()
        await assertAsyncThrows(
            error: IdentityTokenRequestError.twoFactorRequired(
                authMethodsData,
                "BWCaptchaBypass_ABCXYZ",
                nil,
                "exampleToken"
            )
        ) {
            try await subject.loginWithMasterPassword(
                "Password1234!",
                username: "email@example.com",
                captchaToken: nil,
                isNewAccount: false
            )
        }

        // Login with the two-factor code.
        _ = try await subject.loginWithTwoFactorCode(
            email: "email@example.com",
            code: "just_a_lil_code",
            method: .email,
            remember: true
        )

        // Verify the results.
        XCTAssertEqual(
            stateService.forcePasswordResetReason["13512467-9cfe-43b0-969f-07534084764b"],
            .weakMasterPasswordOnLogin
        )
    }

    /// `loginWithTwoFactorCode(email:code:method:remember:captchaToken:)` forcePasswordResetReason is nil since master
    /// password satisfies org policies.
    func test_loginWithTwoFactorCode_forcePasswordResetReason_isNil() async throws {
        // Set up the mock data.
        client.results = [
            .httpSuccess(testData: .preLoginSuccess),
            .httpFailure(
                statusCode: 400,
                headers: [:],
                data: APITestData.identityTokenTwoFactorError.data
            ),
            .httpSuccess(testData: .identityTokenSuccessTwoFactorToken),
        ]
        appSettingsStore.appId = "App id"
        await stateService.setTwoFactorToken("some token", email: "email@example.com")
        clientService.mockAuth.hashPasswordResult = .success("hashed password")
        stateService.preAuthEnvironmentURLs = EnvironmentURLData(base: URL(string: "https://vault.bitwarden.com"))
        systemDevice.modelIdentifier = "Model id"

        let policy = MasterPasswordPolicyOptions(
            minComplexity: 6,
            minLength: 6,
            requireUpper: true,
            requireLower: true,
            requireNumbers: true,
            requireSpecial: true,
            enforceOnLogin: true
        )
        clientService.mockAuth.satisfiesPolicyResult = true
        policyService.getMasterPasswordPolicyOptionsResult = .success(policy)

        // First login with the master password so that the request will be saved.
        let authMethodsData = AuthMethodsData.fixture()
        await assertAsyncThrows(
            error: IdentityTokenRequestError.twoFactorRequired(
                authMethodsData,
                "BWCaptchaBypass_ABCXYZ",
                nil,
                "exampleToken"
            )
        ) {
            try await subject.loginWithMasterPassword(
                "Password1234!",
                username: "email@example.com",
                captchaToken: nil,
                isNewAccount: false
            )
        }

        // Login with the two-factor code.
        _ = try await subject.loginWithTwoFactorCode(
            email: "email@example.com",
            code: "just_a_lil_code",
            method: .email,
            remember: true
        )

        // Verify the results.
        XCTAssertNil(stateService.forcePasswordResetReason["13512467-9cfe-43b0-969f-07534084764b"])
    }

    /// `loginWithTwoFactorCode()` returns the key connector unlock method if the user uses key connector.
    func test_loginWithTwoFactorCode_keyConnector() async throws {
        client.results = [
            .httpSuccess(testData: .preLoginSuccess),
            .httpFailure(
                statusCode: 400,
                headers: [:],
                data: APITestData.identityTokenTwoFactorError.data
            ),
            .httpSuccess(testData: .identityTokenKeyConnector),
        ]

        // First login with the master password so that the request will be saved.
        let authMethodsData = AuthMethodsData.fixture()
        await assertAsyncThrows(
            error: IdentityTokenRequestError.twoFactorRequired(
                authMethodsData,
                "BWCaptchaBypass_ABCXYZ",
                nil,
                "exampleToken"
            )
        ) {
            try await subject.loginWithMasterPassword(
                "Password1234!",
                username: "email@example.com",
                captchaToken: nil,
                isNewAccount: false
            )
        }

        let unlockMethod = try await subject.loginWithTwoFactorCode(
            email: "email@example.com",
            code: "just_a_lil_code",
            method: .email,
            remember: true
        )
        XCTAssertEqual(
            unlockMethod,
            .keyConnector(keyConnectorURL: URL(string: "https://vault.bitwarden.com/key-connector")!)
        )
        await assertGetConfig()
    }

    /// `requirePasswordChange(email:masterPassword:policy)` returns `false` if there
    /// is no policy to check.
    func test_requirePasswordChange_noPolicy() async throws {
        policyService.getMasterPasswordPolicyOptionsResult = .success(nil)
        let requirePasswordChange = try await subject.requirePasswordChange(
            email: "email",
            isPreAuth: false,
            masterPassword: "master password",
            policy: nil
        )
        XCTAssertFalse(requirePasswordChange)
    }

    /// `requirePasswordChange(email:masterPassword:policy)` returns `true` if the master password meet the
    /// master password policy option.
    func test_requirePasswordChange_withPolicy_strong() async throws {
        clientService.mockAuth.satisfiesPolicyResult = true
        policyService.getMasterPasswordPolicyOptionsResult = .success(nil)
        let policy = MasterPasswordPolicyOptions(
            minComplexity: 6,
            minLength: 6,
            requireUpper: false,
            requireLower: false,
            requireNumbers: true,
            requireSpecial: true,
            enforceOnLogin: true
        )
        let requirePasswordChange = try await subject.requirePasswordChange(
            email: "email",
            isPreAuth: false,
            masterPassword: "strong 32 password & #",
            policy: policy
        )
        XCTAssertFalse(requirePasswordChange)
    }

    /// `requirePasswordChange(email:masterPassword:policy)` returns `true` if the master password does not
    /// meet master password policy option.
    func test_requirePasswordChange_withPolicy_weak() async throws {
        clientService.mockAuth.satisfiesPolicyResult = false
        policyService.getMasterPasswordPolicyOptionsResult = .success(nil)
        let policy = MasterPasswordPolicyOptions(
            minComplexity: 6,
            minLength: 6,
            requireUpper: true,
            requireLower: true,
            requireNumbers: true,
            requireSpecial: true,
            enforceOnLogin: true
        )
        let requirePasswordChange = try await subject.requirePasswordChange(
            email: "email",
            isPreAuth: false,
            masterPassword: "weak password",
            policy: policy
        )
        XCTAssertTrue(requirePasswordChange)
    }

    /// `resendNewDeviceOtp()` throws an error if there is no cached request model to use.
    func test_resendNewDeviceOtp_noCache() async throws {
        await assertAsyncThrows(error: AuthError.unableToResendNewDeviceOtp) {
            try await subject.resendNewDeviceOtp()
        }
    }

    /// `resendNewDeviceOtp()` runs successfully.
    func test_resendNewDeviceOtp_success() async throws {
        // Set up the mock data.
        client.results = [
            .httpSuccess(testData: .preLoginSuccess),
            .httpFailure(
                statusCode: 400,
                headers: [:],
                data: APITestData.identityTokenNewDeviceError.data
            ),
            .httpSuccess(testData: .emptyResponse),
        ]
        appSettingsStore.appId = "App id"
        await stateService.setTwoFactorToken("some token", email: "email@example.com")
        clientService.mockAuth.hashPasswordResult = .success("hashed password")
        stateService.preAuthEnvironmentURLs = EnvironmentURLData(base: URL(string: "https://vault.bitwarden.com"))
        systemDevice.modelIdentifier = "Model id"

        // First login with the master password so that the resend email request will be saved.
        await assertAsyncThrows(
            error: IdentityTokenRequestError.newDeviceNotVerified
        ) {
            try await subject.loginWithMasterPassword(
                "Password1234!",
                username: "email@example.com",
                captchaToken: nil,
                isNewAccount: false
            )
        }

        // Ensure the resend email request runs successfully.
        try await subject.resendNewDeviceOtp()

        XCTAssertEqual(client.requests[2].url, URL(
            string: "https://example.com/api/accounts/resend-new-device-otp"
        ))
        let storedToken = await stateService.getTwoFactorToken(email: "email@example.com")
        XCTAssertNil(storedToken)
    }

    /// `resendVerificationCodeEmail()` throws an error if there is no cached request model to use.
    func test_resendVerificationCodeEmail_noCache() async throws {
        await assertAsyncThrows(error: AuthError.unableToResendEmail) {
            try await subject.resendVerificationCodeEmail()
        }
    }

    /// `resendVerificationCodeEmail()` runs successfully.
    func test_resendVerificationCodeEmail_success() async throws {
        // Set up the mock data.
        client.results = [
            .httpSuccess(testData: .preLoginSuccess),
            .httpFailure(
                statusCode: 400,
                headers: [:],
                data: APITestData.identityTokenTwoFactorError.data
            ),
            .httpSuccess(testData: .emptyResponse),
        ]
        appSettingsStore.appId = "App id"
        await stateService.setTwoFactorToken("some token", email: "email@example.com")
        clientService.mockAuth.hashPasswordResult = .success("hashed password")
        stateService.preAuthEnvironmentURLs = EnvironmentURLData(base: URL(string: "https://vault.bitwarden.com"))
        systemDevice.modelIdentifier = "Model id"

        // First login with the master password so that the resend email request will be saved.
        let authMethodsData = AuthMethodsData.fixture()
        await assertAsyncThrows(
            error: IdentityTokenRequestError.twoFactorRequired(
                authMethodsData,
                "BWCaptchaBypass_ABCXYZ",
                nil,
                "exampleToken"
            )
        ) {
            try await subject.loginWithMasterPassword(
                "Password1234!",
                username: "email@example.com",
                captchaToken: nil,
                isNewAccount: false
            )
        }

        // Ensure the resend email request runs successfully.
        try await subject.resendVerificationCodeEmail()
    }

    // MARK: Private

    /// Asserts that `getConfig` is called with the proper parameters
    @MainActor
    private func assertGetConfig() {
        configService.configMocker.assertUnwrapping { forceRefresh, isPreAuth in
            forceRefresh && !isPreAuth
        }
    }
} // swiftlint:disable:this file_length
