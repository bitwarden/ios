import AuthenticationServices
import BitwardenSdk

@available(iOSApplicationExtension 17.0, *)
extension Fido2CredentialAutofillView {
    /// Converts this credential view into an `ASPasskeyCredentialIdentity`.
    /// - Returns: A `ASPasskeyCredentialIdentity` from the values of this object.
    func toFido2CredentialIdentity() -> ASPasskeyCredentialIdentity {
        ASPasskeyCredentialIdentity(
            relyingPartyIdentifier: rpId,
            userName: safeUsernameForUi,
            credentialID: credentialId,
            userHandle: userHandle,
            recordIdentifier: cipherId
        )
    }
}
