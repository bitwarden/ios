import Foundation

@testable import BitwardenShared

class MockAuthService: AuthService {
    var callbackUrlScheme: String = "callback"

    var generateSingleSignOnUrlResult: Result<(URL, String), Error> = .success((url: .example, state: "state"))
    var generateSingleSignOnOrgIdentifier: String?

    var loginWithMasterPasswordPassword: String?
    var loginWithMasterPasswordUsername: String?
    var loginWithMasterPasswordCaptchaToken: String?
    var loginWithMasterPasswordResult: Result<Void, Error> = .success(())

    var loginWithSingleSignOnCode: String?
    var loginWithSingleSignOnResult: Result<Account?, Error> = .success(nil)

    func generateSingleSignOnUrl(from organizationIdentifier: String) async throws -> (url: URL, state: String) {
        generateSingleSignOnOrgIdentifier = organizationIdentifier
        return try generateSingleSignOnUrlResult.get()
    }

    func loginWithMasterPassword(_ password: String, username: String, captchaToken: String?) async throws {
        loginWithMasterPasswordPassword = password
        loginWithMasterPasswordUsername = username
        loginWithMasterPasswordCaptchaToken = captchaToken
        try loginWithMasterPasswordResult.get()
    }

    func loginWithSingleSignOn(code: String) async throws -> Account? {
        loginWithSingleSignOnCode = code
        return try loginWithSingleSignOnResult.get()
    }
}
