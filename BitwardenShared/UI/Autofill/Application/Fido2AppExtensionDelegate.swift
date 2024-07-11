import AuthenticationServices

/// A delegate that is used to handle actions and retrieve information from within an Autofill extension
/// on Fido2 flows.
public protocol Fido2AppExtensionDelegate: AppExtensionDelegate {
    /// The mode in which the autofill extension is running.
    var extensionMode: AutofillExtensionMode { get }

    /// Completes the registration request with a Fido2 credential
    /// - Parameter asPasskeyRegistrationCredential: The passkey credential to be used to complete the registration.
    @available(iOSApplicationExtension 17.0, *)
    func completeRegistrationRequest(asPasskeyRegistrationCredential: ASPasskeyRegistrationCredential)
}

extension Fido2AppExtensionDelegate {
    /// Whether the autofill extension is creating a Fido2 credential.
    var isCreatingFido2Credential: Bool {
        guard case .registerFido2Credential = extensionMode else {
            return false
        }
        return true
    }
}
