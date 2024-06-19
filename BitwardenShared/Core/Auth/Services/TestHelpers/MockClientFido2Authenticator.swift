import BitwardenSdk

@testable import BitwardenShared

class MockClientFido2Authenticator: ClientFido2AuthenticatorProtocol {
    var credentialsForAutofillResult: Result<[Fido2CredentialAutofillView], Error> = .success([])
    var getAssertionResult: Result<BitwardenSdk.GetAssertionResult, Error> = .success(
        BitwardenSdk.GetAssertionResult.fixture()
    )
    var makeCredentialResult: Result<BitwardenSdk.MakeCredentialResult, Error> = .success(
        BitwardenSdk.MakeCredentialResult.fixture()
    )
    var silentlyDiscoverCredentialsResult: Result<[Fido2CredentialAutofillView], Error> = .success([])

    func credentialsForAutofill() async throws -> [Fido2CredentialAutofillView] {
        try credentialsForAutofillResult.get()
    }

    func getAssertion(request: BitwardenSdk.GetAssertionRequest) async throws -> BitwardenSdk.GetAssertionResult {
        try getAssertionResult.get()
    }

    func makeCredential(request: BitwardenSdk.MakeCredentialRequest) async throws -> BitwardenSdk.MakeCredentialResult {
        try makeCredentialResult.get()
    }

    func silentlyDiscoverCredentials(rpId: String) async throws -> [Fido2CredentialAutofillView] {
        try silentlyDiscoverCredentialsResult.get()
    }
}
