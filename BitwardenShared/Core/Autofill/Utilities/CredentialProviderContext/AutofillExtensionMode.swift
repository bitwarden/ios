import AuthenticationServices

/// The autofill extension modes
public enum AutofillExtensionMode {
    /// The extension is autofilling a specific password credential.
    case autofillCredential(ASPasswordCredentialIdentity, userInteraction: Bool)

    /// The extension is displaying a list of password items in the vault that match a service identifier.
    case autofillVaultList([ASCredentialServiceIdentifier])

    /// The extension is autofilling a specific Fido2 credential.
    case autofillFido2Credential(any PasskeyCredentialRequest, userInteraction: Bool)

    /// The extension is displaying a list of items in the vault that match a service identifier
    /// and or passkey request parameters.
    case autofillFido2VaultList([ASCredentialServiceIdentifier], any PasskeyCredentialRequestParameters)

    /// The extension is being configured to set up autofill.
    case configureAutofill

    /// The extension is being configured to register a Fido2 credential.
    case registerFido2Credential(any PasskeyCredentialRequest)
}

/// Protocol to bypass using @available for passkey requests.
public protocol PasskeyCredentialRequest {}
/// Protocol to bypass using @available for passkey request parameters.
public protocol PasskeyCredentialRequestParameters {}

@available(iOSApplicationExtension 17.0, *)
extension ASPasskeyCredentialRequest: PasskeyCredentialRequest {}

@available(iOSApplicationExtension 17.0, *)
extension ASPasskeyCredentialRequestParameters: PasskeyCredentialRequestParameters {}
