import AuthenticationServices

/// A delegate that is used to handle actions and retrieve information from within an Autofill extension
/// on Fido2 flows.
public protocol Fido2AppExtensionDelegate: AppExtensionDelegate {
    /// The mode in which the autofill extension is running.
    var extensionMode: AutofillExtensionMode { get }

    /// Whether the current flow is being executed with user interaction.
    var flowWithUserInteraction: Bool { get }

    /// Completes the assertion request with a Fido2 credential.
    /// - Parameter assertionCredential: The passkey credential to be used to complete the assertion.
    @available(iOSApplicationExtension 17.0, *)
    func completeAssertionRequest(assertionCredential: ASPasskeyAssertionCredential)

    /// Completes the registration request with a Fido2 credential
    /// - Parameter asPasskeyRegistrationCredential: The passkey credential to be used to complete the registration.
    @available(iOSApplicationExtension 17.0, *)
    func completeRegistrationRequest(asPasskeyRegistrationCredential: ASPasskeyRegistrationCredential)

    /// Marks that user interaction is required.
    func setUserInteractionRequired()
}

extension Fido2AppExtensionDelegate {
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
}
