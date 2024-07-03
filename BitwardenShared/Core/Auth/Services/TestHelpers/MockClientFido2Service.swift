import BitwardenSdk

@testable import BitwardenShared

class MockClientFido2Service: ClientFido2Service {
    var clientFido2AuthenticatorMock = MockClientFido2Authenticator()
    var clientFido2ClientMock = MockClientFido2Client()
    var decryptFido2AutofillCredentialsResult: Result<[Fido2CredentialAutofillView], Error> = .success([])

    func authenticator(
        userInterface: any BitwardenSdk.Fido2UserInterface,
        credentialStore: any BitwardenSdk.Fido2CredentialStore
    ) -> BitwardenSdk.ClientFido2AuthenticatorProtocol {
        clientFido2AuthenticatorMock
    }

    func client(
        userInterface: any BitwardenSdk.Fido2UserInterface,
        credentialStore: any BitwardenSdk.Fido2CredentialStore
    ) -> BitwardenSdk.ClientFido2ClientProtocol {
        clientFido2ClientMock
    }

    func decryptFido2AutofillCredentials(cipherView: CipherView) throws -> [Fido2CredentialAutofillView] {
        try decryptFido2AutofillCredentialsResult.get()
    }
}
