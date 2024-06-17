import BitwardenSdk

@testable import BitwardenShared

class MockClientFido2Client: ClientFido2ClientProtocol {
    var authenticateResult: Result<BitwardenSdk.PublicKeyCredentialAuthenticatorAssertionResponse, Error> = .success(
        .fixture()
    )
    var register: Result<BitwardenSdk.PublicKeyCredentialAuthenticatorAttestationResponse, Error> = .success(
        .fixture()
    )

    func authenticate(
        origin: String,
        request: String,
        clientData: BitwardenSdk.ClientData
    ) async throws -> BitwardenSdk.PublicKeyCredentialAuthenticatorAssertionResponse {
        try authenticateResult.get()
    }

    func register(
        origin: String,
        request: String,
        clientData: BitwardenSdk.ClientData
    ) async throws -> BitwardenSdk.PublicKeyCredentialAuthenticatorAttestationResponse {
        try register.get()
    }
}
