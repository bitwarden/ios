import BitwardenSdk
import TestHelpers

@testable import BitwardenShared

class MockClientFido2Service: ClientFido2Service {
    var clientFido2AuthenticatorMock = MockClientFido2Authenticator()
    var clientFido2ClientMock = MockClientFido2Client()
    var decryptFido2AutofillCredentialsMocker =
        InvocationMockerWithThrowingResult<CipherView, [Fido2CredentialAutofillView]>()
            .withResult([.fixture()])

    func client(
        userInterface: any BitwardenSdk.Fido2UserInterface,
        credentialStore: any BitwardenSdk.Fido2CredentialStore,
    ) -> BitwardenSdk.ClientFido2ClientProtocol {
        clientFido2ClientMock
    }

    func decryptFido2AutofillCredentials(cipherView: CipherView) throws -> [Fido2CredentialAutofillView] {
        try decryptFido2AutofillCredentialsMocker.invoke(param: cipherView)
    }

    func vaultAuthenticator(
        userInterface: any BitwardenSdk.Fido2UserInterface,
        credentialStore: any BitwardenSdk.Fido2CredentialStore,
    ) -> BitwardenSdk.ClientFido2AuthenticatorProtocol {
        clientFido2AuthenticatorMock
    }
}
