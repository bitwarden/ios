import BitwardenSdk
import Foundation

@testable import BitwardenShared

class MockAuthService: AuthService {
    var callbackUrlScheme: String = "callback"

    var generateSingleSignOnUrlResult: Result<(URL, String), Error> = .success((url: .example, state: "state"))
    var generateSingleSignOnOrgIdentifier: String?

    var hashPasswordPassword: String?
    var hashPasswordResult: Result<String, Error> = .success("hashed")

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

    var resendVerificationCodeEmailResult: Result<Void, Error> = .success(())

    func generateSingleSignOnUrl(from organizationIdentifier: String) async throws -> (url: URL, state: String) {
        generateSingleSignOnOrgIdentifier = organizationIdentifier
        return try generateSingleSignOnUrlResult.get()
    }

    func hashPassword(password: String, purpose _: HashPurpose) async throws -> String {
        hashPasswordPassword = password
        return try hashPasswordResult.get()
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

    func resendVerificationCodeEmail() async throws {
        try resendVerificationCodeEmailResult.get()
    }
}
