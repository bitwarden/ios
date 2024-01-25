import BitwardenSdk
import Foundation

@testable import BitwardenShared

class MockAuthService: AuthService {
    var accessCode: String = ""
    var callbackUrlScheme: String = "callback"

    var deviceIdentifier: String = ""
    var email: String = ""
    var fingerPrint: String = ""

    var generateSingleSignOnUrlResult: Result<(URL, String), Error> = .success((url: .example, state: "state"))
    var generateSingleSignOnOrgIdentifier: String?

    var hashPasswordPassword: String?
    var hashPasswordResult: Result<String, Error> = .success("hashed")

    var initiateLoginWithDeviceResult: Result<Void, Error> = .success(())

    var loginWithMasterPasswordPassword: String?
    var loginWithMasterPasswordUsername: String?
    var loginWithMasterPasswordCaptchaToken: String?
    var loginWithMasterPasswordResult: Result<Void, Error> = .success(())

    var loginWithSingleSignOnCode: String?
    var loginWithSingleSignOnResult: Result<Account?, Error> = .success(nil)

    var publicKey: String = ""

    func generateSingleSignOnUrl(from organizationIdentifier: String) async throws -> (url: URL, state: String) {
        generateSingleSignOnOrgIdentifier = organizationIdentifier
        return try generateSingleSignOnUrlResult.get()
    }

    func hashPassword(password: String, purpose _: HashPurpose) async throws -> String {
        hashPasswordPassword = password
        return try hashPasswordResult.get()
    }

    func initiateLoginWithDevice(
        accessCode: String,
        deviceIdentifier: String,
        email: String,
        fingerPrint: String,
        publicKey: String
    ) async throws {
        self.accessCode = accessCode
        self.deviceIdentifier = deviceIdentifier
        self.email = email
        self.fingerPrint = fingerPrint
        self.publicKey = publicKey

        try initiateLoginWithDeviceResult.get()
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
