import AuthenticationServices

/// A delegate that is used to handle actions and retrieve information from within an Autofill extension
/// on Fido2 flows.
public protocol Fido2AppExtensionDelegate: AppExtensionDelegate {
    @available(iOSApplicationExtension 17.0, *)
    func completeRegistrationRequest(asPasskeyRegistrationCredential: ASPasskeyRegistrationCredential)

    @available(iOSApplicationExtension 17.0, *)
    func getRequestForFido2Creation() -> ASPasskeyCredentialRequest?
}

@available(iOSApplicationExtension 17.0, *)
extension Fido2AppExtensionDelegate {
    var isCreatingFido2Credential: Bool { getRequestForFido2Creation() != nil }
}
