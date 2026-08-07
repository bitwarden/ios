import BitwardenSdk

// MARK: - UsePasskeyEffect

/// Effects that can be processed by an `UsePasskeyProcessor`.
///
enum UsePasskeyEffect: Equatable {
    /// The view appeared, and should load the list of registered credentials.
    case loadRegisteredCredentials

    /// The user selected a credential from the registered credentials list.
    case selectCredential(Fido2CredentialAutofillView)
}
