import AuthenticationServices

/// An enumeration that describes how the extension is being used.
///
enum PasswordExtensionMode: Equatable {
    /// The extension is autofilling a specific credential.
    case autofillCredential(ASPasswordCredentialIdentity)

    /// The extension is displaying a list of password items in the vault that match a service identifier.
    case autofillVaultList([ASCredentialServiceIdentifier])

    /// The extension is being configured to set up autofill.
    case configureAutofill
}

@available(iOSApplicationExtension 17.0, *)
enum ExtensionMode: Equatable {
    /// The extension is autofilling a specific credential.
    case autofillCredential(ASPasskeyCredentialRequest)

    /// The extension is displaying a list of items in the vault that match a service identifier
    /// and or passkey request parameters.
    case autofillVaultList([ASCredentialServiceIdentifier], ASPasskeyCredentialRequestParameters)

    /// The extension is being configured to set up autofill.
    case configureAutofill

    /// The extension is being configured to register a Fido2 credential.
    case registerFido2Credential(ASPasskeyCredentialRequest)
}
