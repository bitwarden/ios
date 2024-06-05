import AuthenticationServices

@testable import BitwardenShared

class MockAutofillCredentialService: AutofillCredentialService {
    var provideCredentialPasswordCredential: ASPasswordCredential?
    var provideCredentialError: Error?

    func provideCredential(for id: String, repromptPasswordValidated: Bool) async throws -> ASPasswordCredential {
        guard let provideCredentialPasswordCredential else {
            throw provideCredentialError ?? ASExtensionError(.failed)
        }
        return provideCredentialPasswordCredential
    }
}
