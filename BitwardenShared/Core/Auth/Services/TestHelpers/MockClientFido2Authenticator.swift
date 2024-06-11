import BitwardenSdk

@testable import BitwardenShared

class MockClientFido2Authenticator: ClientFido2AuthenticatorProtocol {
    var getAssertionResult: Result<BitwardenSdk.GetAssertionResult, Error> = .success(BitwardenSdk.GetAssertionResult.fixture())
    var makeCredentialResult: Result<BitwardenSdk.MakeCredentialResult, Error> = .success(BitwardenSdk.MakeCredentialResult.fixture())
    var silentlyDiscoverCredentials: Result<[BitwardenSdk.Fido2CredentialView], Error> = .success([])

    func getAssertion(request: BitwardenSdk.GetAssertionRequest) async throws -> BitwardenSdk.GetAssertionResult {
        try getAssertionResult.get()
    }
    
    func makeCredential(request: BitwardenSdk.MakeCredentialRequest) async throws -> BitwardenSdk.MakeCredentialResult {
        try makeCredentialResult.get()
    }
    
    func silentlyDiscoverCredentials(rpId: String) async throws -> [BitwardenSdk.Fido2CredentialView] {
        try silentlyDiscoverCredentials.get()
    }
}
