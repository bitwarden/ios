import AuthenticationServices
import Combine

/// A delegate that is used to handle actions and retrieve information from within an Autofill extension
/// on credential provider flows.
@MainActor
public protocol AutofillAppExtensionDelegate: AppExtensionDelegate {
    /// The mode in which the autofill extension is running.
    var extensionMode: AutofillExtensionMode { get }

    /// Whether the current flow is being executed with user interaction.
    var flowWithUserInteraction: Bool { get }

    /// Completes the assertion request with a Fido2 credential.
    /// - Parameter assertionCredential: The passkey credential to be used to complete the assertion.
    @available(iOSApplicationExtension 17.0, *)
    func completeAssertionRequest(assertionCredential: ASPasskeyAssertionCredential)

    /// Completes the autofill OTP request with the specified code.
    /// - Parameter code: The code to autofill.
    @available(iOSApplicationExtension 18.0, *)
    func completeOTPRequest(code: String)

    /// Completes the registration request with a Fido2 credential
    /// - Parameter asPasskeyRegistrationCredential: The passkey credential to be used to complete the registration.
    @available(iOSApplicationExtension 17.0, *)
    func completeRegistrationRequest(asPasskeyRegistrationCredential: ASPasskeyRegistrationCredential)

    /// Completes the text request with some text to insert.
    @available(iOSApplicationExtension 18.0, *)
    func completeTextRequest(text: String)

    /// Gets a publisher for when `didAppear` happens.
    func getDidAppearPublisher() -> AsyncPublisher<AnyPublisher<Bool, Never>>

    /// Marks that user interaction is required.
    func setUserInteractionRequired()
}

extension AutofillAppExtensionDelegate {
    /// Gets the mode in which the autofill list should run.
    var autofillListMode: AutofillListMode {
        switch extensionMode {
        case .autofillFido2VaultList:
            .combinedMultipleSections
        case .autofillOTP:
            .totp
        case .autofillText:
            .all
        case .registerFido2Credential:
            .combinedSingleSection
        default:
            .passwords
        }
    }

    /// Whether the autofill extension is creating a Fido2 credential.
    var isCreatingFido2Credential: Bool {
        guard case .registerFido2Credential = extensionMode else {
            return false
        }
        return true
    }

    /// Whether the autofill extension is autofilling a Fido2 credential from list.
    var isAutofillingFido2CredentialFromList: Bool {
        guard case .autofillFido2VaultList = extensionMode else {
            return false
        }
        return true
    }

    /// Gets the current relying party identifier depending on the extension mode.
    var rpID: String? {
        switch extensionMode {
        case let .autofillFido2VaultList(_, parameters):
            return parameters.relyingPartyIdentifier
        case let .registerFido2Credential(passkeyRequest):
            guard #available(iOSApplicationExtension 17.0, *),
                  let asPasskeyRequest = passkeyRequest as? ASPasskeyCredentialRequest else {
                return nil
            }

            // For authentication requests, the rpID is available through credentialIdentity
            if let credentialIdentity = asPasskeyRequest.credentialIdentity as? ASPasskeyCredentialIdentity {
                return credentialIdentity.relyingPartyIdentifier
            }

            // For registration requests (iOS 18+), try to get rpID from the request properties
            // Note: In iOS 17, during registration the credentialIdentity is nil, and we need
            // to rely on the CredentialProviderContext fallback to extract rpID from serviceIdentifiers
            // or from the processor's workaround.
            if #available(iOSApplicationExtension 18.0, *) {
                // In iOS 18+, ASPasskeyCredentialRequest for registration may have additional
                // properties to access the relying party identifier. Check for these properties.
                // As of iOS 18, the API doesn't provide a direct property for registration requests,
                // so this remains nil and we rely on the fallback in CredentialProviderContext.
            }

            return nil
        default:
            return nil
        }
    }
}
