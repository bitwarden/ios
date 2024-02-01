import BitwardenSdk
import Foundation

@testable import BitwardenShared

class MockAuthService: AuthService {
    var answerLoginRequestApprove: Bool?
    var answerLoginRequestResult: Result<Void, Error> = .success(())
    var answerLoginRequestRequest: LoginRequest?

    var callbackUrlScheme: String = "callback"

    var denyAllLoginRequestsResult: Result<Void, Error> = .success(())
    var denyAllLoginRequestsRequests: [LoginRequest]?

    var generateSingleSignOnUrlResult: Result<(URL, String), Error> = .success((url: .example, state: "state"))
    var generateSingleSignOnOrgIdentifier: String?

    var getPendingLoginRequestCalled = false
    var getPendingLoginRequestId: String?
    var getPendingLoginRequestResult: Result<[LoginRequest], Error> = .success([])

    var hashPasswordPassword: String?
    var hashPasswordResult: Result<String, Error> = .success("hashed")

    var initiateLoginWithDeviceEmail: String?
    var initiateLoginWithDeviceResult: Result<String, Error> = .success("")

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

    func answerLoginRequest(_ request: LoginRequest, approve: Bool) async throws {
        answerLoginRequestRequest = request
        answerLoginRequestApprove = approve
        try answerLoginRequestResult.get()
    }

    func denyAllLoginRequests(_ requests: [LoginRequest]) async throws {
        denyAllLoginRequestsRequests = requests
        try denyAllLoginRequestsResult.get()
    }

    func generateSingleSignOnUrl(from organizationIdentifier: String) async throws -> (url: URL, state: String) {
        generateSingleSignOnOrgIdentifier = organizationIdentifier
        return try generateSingleSignOnUrlResult.get()
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

    func initiateLoginWithDevice(email: String) async throws -> String {
        initiateLoginWithDeviceEmail = email
        return try initiateLoginWithDeviceResult.get()
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
    ) async throws -> Account {
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
        try resendVerificationCodeEmailResult.get()
    }
}
