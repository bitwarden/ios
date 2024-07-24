import AuthenticationServices
import BitwardenSdk

@testable import BitwardenShared

// MARK: - MockAutofillCredentialService

class MockAutofillCredentialService: AutofillCredentialService {
    var provideCredentialPasswordCredential: ASPasswordCredential?
    var provideCredentialError: Error?
    var provideFido2CredentialResult: Result<PasskeyAssertionCredential, Error> = .failure(BitwardenTestError.example)

    func provideCredential(
        for id: String,
        autofillCredentialServiceDelegate: AutofillCredentialServiceDelegate,
        repromptPasswordValidated: Bool
    ) async throws -> ASPasswordCredential {
        guard let provideCredentialPasswordCredential else {
            throw provideCredentialError ?? ASExtensionError(.failed)
        }
        return provideCredentialPasswordCredential
    }

    @available(iOS 17.0, *)
    func provideFido2Credential(
        for passkeyRequest: ASPasskeyCredentialRequest,
        autofillCredentialServiceDelegate: AutofillCredentialServiceDelegate,
        fido2UserInterfaceHelperDelegate: Fido2UserInterfaceHelperDelegate
    ) async throws -> ASPasskeyAssertionCredential {
        let result = try provideFido2CredentialResult.get()
        guard let credential = result as? ASPasskeyAssertionCredential else {
            throw Fido2Error.invalidOperationError
        }
        return credential
    }
}

// MARK: - PasskeyAssertionCredential

/// Protocol to bypass using @available for passkey assertion credential.
public protocol PasskeyAssertionCredential {}

@available(iOS 17.0, *)
extension ASPasskeyAssertionCredential: PasskeyAssertionCredential {}

// MARK: - MockPasskeyAssertionCredential

class MockPasskeyAssertionCredential: PasskeyAssertionCredential {}
