import BitwardenSdk

@testable import BitwardenShared

class MockClientFido2Service: ClientFido2Service {
    var clientFido2Authenticator: BitwardenSdk.ClientFido2AuthenticatorProtocol = MockClientFido2Authenticator()
    var clientFido2Client: BitwardenSdk.ClientFido2ClientProtocol = MockClientFido2Client()
    var decryptFido2AutofillCredentialsResult: Result<[Fido2CredentialAutofillView], Error> = .success([])

    func authenticator(
        userInterface: any BitwardenSdk.Fido2UserInterface,
        credentialStore: any BitwardenSdk.Fido2CredentialStore
    ) -> BitwardenSdk.ClientFido2AuthenticatorProtocol {
        clientFido2Authenticator
    }

    func client(
        userInterface: any BitwardenSdk.Fido2UserInterface,
        credentialStore: any BitwardenSdk.Fido2CredentialStore
    ) -> BitwardenSdk.ClientFido2ClientProtocol {
        clientFido2Client
    }

    func decryptFido2AutofillCredentials(cipherView: CipherView) throws -> [Fido2CredentialAutofillView] {
        try decryptFido2AutofillCredentialsResult.get()
    }
}
