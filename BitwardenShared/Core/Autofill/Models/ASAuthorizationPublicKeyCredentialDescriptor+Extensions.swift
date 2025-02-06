import AuthenticationServices
import BitwardenSdk

/// Extension with helpers for `ASAuthorizationPublicKeyCredentialDescriptor`.
extension ASAuthorizationPublicKeyCredentialDescriptor {
    /// Maps to a `PublicKeyCredentialDescriptor`.
    /// - Returns: A `PublicKeyCredentialDescriptor` mapped from this instance.
    func toPublicKeyCredentialDescriptor() -> PublicKeyCredentialDescriptor {
        PublicKeyCredentialDescriptor(
            ty: Constants.defaultFido2PublicKeyCredentialType,
            id: credentialID,
            transports: nil
        )
    }
}
