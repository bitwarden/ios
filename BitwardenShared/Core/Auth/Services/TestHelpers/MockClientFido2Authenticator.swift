import BitwardenSdk

@testable import BitwardenShared

class MockClientFido2Authenticator: ClientFido2AuthenticatorProtocol {
    var credentialsForAutofillResult: Result<[Fido2CredentialAutofillView], Error> = .success([])
    var getAssertionMocker = InvocationMockerWithThrowingResult<GetAssertionRequest, GetAssertionResult>()
        .withResult(.fixture())
    var makeCredentialMocker = InvocationMockerWithThrowingResult<MakeCredentialRequest, MakeCredentialResult>()
        .withResult(.fixture())
    var silentlyDiscoverCredentialsResult: Result<[Fido2CredentialAutofillView], Error> = .success([])

    func credentialsForAutofill() async throws -> [Fido2CredentialAutofillView] {
        try credentialsForAutofillResult.get()
    }

    func getAssertion(request: BitwardenSdk.GetAssertionRequest) async throws -> BitwardenSdk.GetAssertionResult {
        try getAssertionMocker.invoke(param: request)
    }

    func makeCredential(request: BitwardenSdk.MakeCredentialRequest) async throws -> BitwardenSdk.MakeCredentialResult {
        try makeCredentialMocker.invoke(param: request)
    }

    func silentlyDiscoverCredentials(rpId: String) async throws -> [Fido2CredentialAutofillView] {
        try silentlyDiscoverCredentialsResult.get()
    }
}
