import AuthenticationServices

/// The credential provider extension modes
public enum CredentialProviderMode {
    /// The extension is autofilling a specific password credential.
    case autofillCredential(ASPasswordCredentialIdentity, userInteraction: Bool)

    /// The extension is displaying a list of OTP items in the vault that match a service identifier.
    case autofillOTP([ASCredentialServiceIdentifier])

    /// The extension is autofilling a specific OTP credential.
    case autofillOTPCredential(OneTimeCodeCredentialIdentityProxy, userInteraction: Bool)

    /// The extension is called from the context menu of a field to autofill some text.
    /// This is generic so we can auotfill pretty much anything the user chooses.
    case autofillText

    /// The extension is displaying a list of password items in the vault that match a service identifier.
    case autofillVaultList([ASCredentialServiceIdentifier])

    /// The extension is autofilling a specific Fido2 credential.
    case autofillFido2Credential(any PasskeyCredentialRequest, userInteraction: Bool)

    /// The extension is displaying a list of items in the vault that match a service identifier
    /// and or passkey request parameters.
    case autofillFido2VaultList([ASCredentialServiceIdentifier], any PasskeyCredentialRequestParameters)

    /// The extension is being configured to set up autofill.
    case configureAutofill

    /// The extension is generating a password without user interaction.
    case generatePasswordWithoutUserInteraction

    /// The extension is being configured to register a Fido2 credential.
    case registerFido2Credential(any PasskeyCredentialRequest)

    /// The extension is saving a password credential without user interaction.
    case savePasswordWithoutUserInteraction(any SavePasswordRequestProxy)
}

/// Protocol to bypass using @available for passkey requests.
public protocol PasskeyCredentialRequest {}

/// Protocol to bypass using @available for OTP credential identities.
public protocol OneTimeCodeCredentialIdentityProxy {}

/// Protocol to bypass using @available for save password requests (iOS 26.2+).
public protocol SavePasswordRequestProxy {}

@available(iOSApplicationExtension 17.0, *)
extension ASPasskeyCredentialRequest: PasskeyCredentialRequest {}

@available(iOSApplicationExtension 18.0, *)
extension ASOneTimeCodeCredentialIdentity: OneTimeCodeCredentialIdentityProxy {}

@available(iOSApplicationExtension 26.2, *)
extension ASSavePasswordRequest: SavePasswordRequestProxy {}
