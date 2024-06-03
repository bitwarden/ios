import AuthenticationServices
import BitwardenSdk
import Foundation

@testable import BitwardenShared

class MockAuthService: AuthService {
    var answerLoginRequestApprove: Bool?
    var answerLoginRequestResult: Result<Void, Error> = .success(())
    var answerLoginRequestRequest: LoginRequest?

    var callbackUrlScheme: String = "callback"

    var checkPendingLoginRequestId: String?
    var checkPendingLoginRequestResult: Result<LoginRequest, Error> = .success(.fixture())

    var denyAllLoginRequestsResult: Result<Void, Error> = .success(())
    var denyAllLoginRequestsRequests: [LoginRequest]?

    var generateSingleSignOnUrlResult: Result<(URL, String), Error> = .success((url: .example, state: "state"))
    var generateSingleSignOnOrgIdentifier: String?

    var getPendingAdminLoginRequestUserId: String?
    var getPendingAdminLoginRequestResult: Result<PendingAdminLoginRequest, Error> = .success(.fixture())

    var getPendingLoginRequestCalled = false
    var getPendingLoginRequestId: String?
    var getPendingLoginRequestResult: Result<[LoginRequest], Error> = .success([])

    var hashPasswordPassword: String?
    var hashPasswordResult: Result<String, Error> = .success("hashed")

    var initiateLoginWithDeviceEmail: String?
    var initiateLoginWithDeviceType: AuthRequestType?
    var initiateLoginWithDeviceResult: Result<
        (authRequestResponse: AuthRequestResponse, requestId: String), Error
    > = .success((.fixture(), ""))

    var loginWithDeviceRequest: LoginRequest?
    var loginWithDeviceEmail: String?
    var loginWithDeviceCaptchaToken: String?
    var loginWithDeviceIsAuthenticated: Bool?
    var loginWithDeviceResult: Result<(String, String), Error> = .success(("", ""))

    var loginWithMasterPasswordPassword: String?
    var loginWithMasterPasswordUsername: String?
    var loginWithMasterPasswordCaptchaToken: String?
    var loginWithMasterPasswordResult: Result<Void, Error> = .success(())

    var loginWithSingleSignOnCode: String?
    var loginWithSingleSignOnResult: Result<Account?, Error> = .success(nil)

    var loginWithTwoFactorCodeEmail: String?
    var loginWithTwoFactorCodeCode: String?
    var loginWithTwoFactorCodeMethod: TwoFactorAuthMethod?
    var loginWithTwoFactorCodeRemember: Bool?
    var loginWithTwoFactorCodeCaptchaToken: String?
    var loginWithTwoFactorCodeResult: Result<Account, Error> = .success(.fixture())
    var publicKey: String = ""
    var requirePasswordChangeResult: Result<Bool, Error> = .success(false)
    var resendVerificationCodeEmailResult: Result<Void, Error> = .success(())
    var sentVerificationEmail = false

    var setPendingAdminLoginRequest: PendingAdminLoginRequest?
    var setPendingAdminLoginRequestResult: Result<Void, Error> = .success(())

    var webAuthenticationSession: ASWebAuthenticationSession?

    func answerLoginRequest(_ request: LoginRequest, approve: Bool) async throws {
        answerLoginRequestRequest = request
        answerLoginRequestApprove = approve
        try answerLoginRequestResult.get()
    }

    func checkPendingLoginRequest(withId id: String) async throws -> LoginRequest {
        checkPendingLoginRequestId = id
        return try checkPendingLoginRequestResult.get()
    }

    func denyAllLoginRequests(_ requests: [LoginRequest]) async throws {
        denyAllLoginRequestsRequests = requests
        try denyAllLoginRequestsResult.get()
    }

    func generateSingleSignOnUrl(from organizationIdentifier: String) async throws -> (url: URL, state: String) {
        generateSingleSignOnOrgIdentifier = organizationIdentifier
        return try generateSingleSignOnUrlResult.get()
    }

    func getPendingAdminLoginRequest(userId: String?) async throws -> PendingAdminLoginRequest? {
        getPendingAdminLoginRequestUserId = userId
        return try getPendingAdminLoginRequestResult.get()
    }

    func getPendingLoginRequest(withId id: String?) async throws -> [LoginRequest] {
        getPendingLoginRequestCalled = true
        getPendingLoginRequestId = id
        return try getPendingLoginRequestResult.get()
    }

    func hashPassword(password: String, purpose _: HashPurpose) async throws -> String {
        hashPasswordPassword = password
        return try hashPasswordResult.get()
    }

    func initiateLoginWithDevice(
        email: String,
        type: AuthRequestType
    ) async throws -> (authRequestResponse: AuthRequestResponse, requestId: String) {
        initiateLoginWithDeviceEmail = email
        initiateLoginWithDeviceType = type
        return try initiateLoginWithDeviceResult.get()
    }

    func loginWithDevice(
        _ loginRequest: LoginRequest,
        email: String,
        isAuthenticated: Bool,
        captchaToken: String?
    ) async throws -> (String, String) {
        loginWithDeviceRequest = loginRequest
        loginWithDeviceEmail = email
        loginWithDeviceIsAuthenticated = isAuthenticated
        loginWithDeviceCaptchaToken = captchaToken
        return try loginWithDeviceResult.get()
    }

    func loginWithMasterPassword(_ password: String, username: String, captchaToken: String?) async throws {
        loginWithMasterPasswordPassword = password
        loginWithMasterPasswordUsername = username
        loginWithMasterPasswordCaptchaToken = captchaToken
        try loginWithMasterPasswordResult.get()
    }

    func loginWithSingleSignOn(code: String, email _: String) async throws -> Account? {
        loginWithSingleSignOnCode = code
        return try loginWithSingleSignOnResult.get()
    }

    func loginWithTwoFactorCode(
        email: String,
        code: String,
        method: TwoFactorAuthMethod,
        remember: Bool,
        captchaToken: String?
    ) async throws -> Account? {
        loginWithTwoFactorCodeEmail = email
        loginWithTwoFactorCodeCode = code
        loginWithTwoFactorCodeMethod = method
        loginWithTwoFactorCodeRemember = remember
        loginWithTwoFactorCodeCaptchaToken = captchaToken
        return try loginWithTwoFactorCodeResult.get()
    }

    func requirePasswordChange(
        email: String,
        masterPassword: String,
        policy: BitwardenSdk.MasterPasswordPolicyOptions?
    ) async throws -> Bool {
        try requirePasswordChangeResult.get()
    }

    func resendVerificationCodeEmail() async throws {
        sentVerificationEmail = true
        try resendVerificationCodeEmailResult.get()
    }

    func setPendingAdminLoginRequest(_ adminLoginRequest: PendingAdminLoginRequest?, userId: String?) async throws {
        setPendingAdminLoginRequest = adminLoginRequest
        try setPendingAdminLoginRequestResult.get()
    }

    func webAuthenticationSession(
        url: URL,
        completionHandler: @escaping ASWebAuthenticationSession.CompletionHandler
    ) -> ASWebAuthenticationSession {
        let mockSession = MockWebAuthenticationSession(
            url: url,
            callbackURLScheme: callbackUrlScheme,
            completionHandler: completionHandler
        )
        webAuthenticationSession = mockSession
        return mockSession
    }
}

// MARK: - MockWebAuthenticationSession

class MockWebAuthenticationSession: ASWebAuthenticationSession {
    var startCalled = false
    var startReturn = true

    var initUrl: URL
    var initCallbackURLScheme: String?
    var initCompletionHandler: ASWebAuthenticationSession.CompletionHandler

    override init(
        url URL: URL,
        callbackURLScheme: String?,
        completionHandler: @escaping ASWebAuthenticationSession.CompletionHandler
    ) {
        initUrl = URL
        initCallbackURLScheme = callbackURLScheme
        initCompletionHandler = completionHandler
        super.init(url: URL, callbackURLScheme: callbackURLScheme, completionHandler: completionHandler)
    }

    override func start() -> Bool {
        startCalled = true
        return startReturn
    }
}
