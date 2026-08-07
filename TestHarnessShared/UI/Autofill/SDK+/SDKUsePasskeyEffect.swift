import BitwardenSdk

// MARK: - SDKUsePasskeyEffect

/// Effects that can be processed by an `SDKUsePasskeyProcessor`.
///
enum SDKUsePasskeyEffect: Equatable {
    /// The user requested deletion of a registered credential.
    case deleteCredential(Fido2CredentialAutofillView)

    /// The view appeared, and should load the list of registered credentials.
    case loadRegisteredCredentials

    /// The user selected a credential from the registered credentials list.
    case selectCredential(Fido2CredentialAutofillView)
}
