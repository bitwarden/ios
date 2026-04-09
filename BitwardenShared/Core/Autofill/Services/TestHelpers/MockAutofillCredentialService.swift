import AuthenticationServices
import BitwardenSdk
import TestHelpers

@testable import BitwardenShared

// MARK: - MockAutofillCredentialService

class MockAutofillCredentialService: AutofillCredentialService {
    var isAutofillCredentialsEnabled = false
    var provideCredentialPasswordCredential: ASPasswordCredential?
    var provideCredentialError: Error?
    var provideFido2CredentialResult: Result<PasskeyAssertionCredential, Error> = .failure(BitwardenTestError.example)
    var provideOTPCredentialResult: Result<OneTimeCodeCredential, Error> = .failure(BitwardenTestError.example)
    var updateCredentialsInStoreCalled = false

    func isAutofillCredentialsEnabled() async -> Bool {
        isAutofillCredentialsEnabled
    }

    func provideCredential(
        for id: String,
        autofillCredentialServiceDelegate: AutofillCredentialServiceDelegate,
        repromptPasswordValidated: Bool,
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
        fido2UserInterfaceHelperDelegate: Fido2UserInterfaceHelperDelegate,
    ) async throws -> ASPasskeyAssertionCredential {
        let result = try provideFido2CredentialResult.get()
        guard let credential = result as? ASPasskeyAssertionCredential else {
            throw Fido2Error.invalidOperationError
        }
        return credential
    }

    @available(iOS 17.0, *)
    func provideFido2Credential(
        for fido2RequestParameters: PasskeyCredentialRequestParameters,
        fido2UserInterfaceHelperDelegate: Fido2UserInterfaceHelperDelegate,
    ) async throws -> ASPasskeyAssertionCredential {
        let result = try provideFido2CredentialResult.get()
        guard let credential = result as? ASPasskeyAssertionCredential else {
            throw Fido2Error.invalidOperationError
        }
        return credential
    }

    @available(iOS 18.0, *)
    func provideOTPCredential(
        for id: String,
        autofillCredentialServiceDelegate: any BitwardenShared.AutofillCredentialServiceDelegate,
        repromptPasswordValidated: Bool,
    ) async throws -> ASOneTimeCodeCredential {
        let result = try provideOTPCredentialResult.get()
        guard let credential = result as? ASOneTimeCodeCredential else {
            throw Fido2Error.invalidOperationError
        }
        return credential
    }

    func updateCredentialsInStore() async {
        updateCredentialsInStoreCalled = true
    }
}

// MARK: - PasskeyAssertionCredential

/// Protocol to bypass using @available for passkey assertion credential.
public protocol PasskeyAssertionCredential {}

@available(iOS 17.0, *)
extension ASPasskeyAssertionCredential: PasskeyAssertionCredential {}

// MARK: - MockPasskeyAssertionCredential

class MockPasskeyAssertionCredential: PasskeyAssertionCredential {}

// MARK: - OneTimeCodeCredential

/// Protocol to bypass using @available for one time code credential.
public protocol OneTimeCodeCredential {}

@available(iOS 18.0, *)
extension ASOneTimeCodeCredential: OneTimeCodeCredential {}

// MARK: - MockOneTimeCodeCredential

class MockOneTimeCodeCredential: OneTimeCodeCredential {}
