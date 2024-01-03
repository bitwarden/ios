import Foundation

@testable import BitwardenShared

class MockAuthService: AuthService {
    var callbackUrlScheme: String = "callback"

    var generateSingleSignOnUrlResult: Result<(URL, String), Error> = .success((.example, "state"))
    var generateSingleSignOnOrgIdentifier: String?

    var loginSingleSignOnCode: String?
    var loginSingleSignOnResult: Result<Account?, Error> = .success(nil)

    func generateSingleSignOnUrl(from organizationIdentifier: String) async throws -> (URL, String) {
        generateSingleSignOnOrgIdentifier = organizationIdentifier
        return try generateSingleSignOnUrlResult.get()
    }

    func loginSingleSignOn(code: String) async throws -> Account? {
        loginSingleSignOnCode = code
        return try loginSingleSignOnResult.get()
    }
}
