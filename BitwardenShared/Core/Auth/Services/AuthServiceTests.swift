import BitwardenSdk
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
    var environmentService: MockEnvironmentService!
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
        environmentService = MockEnvironmentService()
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
            environmentService: environmentService,
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
        environmentService = nil
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
    }

    /// `loginWithDevice(_:email:captchaToken:)` throws an error if there's no cached data.
    func test_loginWithDevice_error() async throws {
        await assertAsyncThrows(error: AuthError.missingLoginWithDeviceData) {
            _ = try await subject.loginWithDevice(.fixture(), email: "", captchaToken: nil)
        }
    }

    /// `loginWithMasterPassword(_:username:captchaToken:)` logs in with the password.
    func test_loginWithMasterPassword() async throws { // swiftlint:disable:this function_body_length
        // Set up the mock data.
        client.results = [
            .httpSuccess(testData: .preLoginSuccess),
            .httpSuccess(testData: .identityTokenSuccess),
        ]
        appSettingsStore.appId = "App id"
        clientService.mockAuth.hashPasswordResult = .success("hashed password")
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
    }

    /// `loginWithMasterPassword(_:username:captchaToken:)` logs in with the password updates AccountProfile's
    /// `.forcePasswordResetReason` value if policy requires user to update password.
    func test_loginWithMasterPassword_updatesAccountProfile() async throws {
        // Set up the mock data.
        client.results = [
            .httpSuccess(testData: .preLoginSuccess),
            .httpSuccess(testData: .identityTokenWithMasterPasswordPolicy),
        ]
        appSettingsStore.appId = "App id"
        clientService.mockAuth.hashPasswordResult = .success("hashed password")
        clientService.mockAuth.satisfiesPolicyResult = false
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
        stateService.preAuthEnvironmentUrls = EnvironmentUrlData(base: URL(string: "https://vault.bitwarden.com"))
        systemDevice.modelIdentifier = "Model id"

        // Attempt to login.
        let authMethodsData = AuthMethodsData.fixture()
        await assertAsyncThrows(
            error: IdentityTokenRequestError.twoFactorRequired(
                authMethodsData,
                "exampleToken",
                "BWCaptchaBypass_ABCXYZ"
            )
        ) {
            try await subject.loginWithMasterPassword(
                "Password1234!",
                username: "email@example.com",
                captchaToken: nil
            )
        }

        // Verify the results.
        let cachedToken = await stateService.getTwoFactorToken(email: "email@example.com")
        XCTAssertNil(cachedToken)
    }

    /// `loginWithSingleSignOn(code:email:)` throws an error if the user doesn't have a master password set.
    func test_loginSingleSignOn_noMasterPassword() async {
        client.result = .httpSuccess(testData: .identityTokenNoMasterPassword)

        await assertAsyncThrows(error: AuthError.requireSetPassword) {
            _ = try await subject.loginWithSingleSignOn(code: "super_cool_secret_code", email: "")
        }
    }

    /// `loginWithSingleSignOn(code:email:)` returns an account if the vault is still locked after authenticating.
    func test_loginSingleSignOn_vaultLocked() async throws {
        // Set up the mock data.
        appSettingsStore.appId = "App id"
        client.result = .httpSuccess(testData: .identityTokenSuccess)
        stateService.preAuthEnvironmentUrls = EnvironmentUrlData(base: URL(string: "https://vault.bitwarden.com"))
        systemDevice.modelIdentifier = "Model id"

        // Attempt to login.
        let account = try await subject.loginWithSingleSignOn(code: "super_cool_secret_code", email: "")

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

        XCTAssertEqual(account, .fixtureAccountLogin())
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
        stateService.preAuthEnvironmentUrls = EnvironmentUrlData(base: URL(string: "https://vault.bitwarden.com"))
        systemDevice.modelIdentifier = "Model id"

        // First login with the master password so that the request will be saved.
        let authMethodsData = AuthMethodsData.fixture()
        await assertAsyncThrows(
            error: IdentityTokenRequestError.twoFactorRequired(
                authMethodsData,
                "exampleToken",
                "BWCaptchaBypass_ABCXYZ"
            )
        ) {
            try await subject.loginWithMasterPassword(
                "Password1234!",
                username: "email@example.com",
                captchaToken: nil
            )
        }

        // Login with the two-factor code.
        let account = try await subject.loginWithTwoFactorCode(
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

        XCTAssertEqual(account, .fixtureAccountLogin())
    }

    /// `requirePasswordChange(email:masterPassword:policy)` returns `false` if there
    /// is no policy to check.
    func test_requirePasswordChange_noPolicy() async throws {
        policyService.getMasterPasswordPolicyOptionsResult = .success(nil)
        let requirePasswordChange = try await subject.requirePasswordChange(
            email: "email",
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
            masterPassword: "weak password",
            policy: policy
        )
        XCTAssertTrue(requirePasswordChange)
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
        stateService.preAuthEnvironmentUrls = EnvironmentUrlData(base: URL(string: "https://vault.bitwarden.com"))
        systemDevice.modelIdentifier = "Model id"

        // First login with the master password so that the resend email request will be saved.
        let authMethodsData = AuthMethodsData.fixture()
        await assertAsyncThrows(
            error: IdentityTokenRequestError.twoFactorRequired(
                authMethodsData,
                "exampleToken",
                "BWCaptchaBypass_ABCXYZ"
            )
        ) {
            try await subject.loginWithMasterPassword(
                "Password1234!",
                username: "email@example.com",
                captchaToken: nil
            )
        }

        // Ensure the resend email request runs successfully.
        try await subject.resendVerificationCodeEmail()
    }
} // swiftlint:disable:this file_length
