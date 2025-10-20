import AuthenticationServices
import BitwardenKit
import BitwardenSdk

/// Extension with helpers for `PublicKeyCredentialDescriptor`.
extension PublicKeyCredentialDescriptor {
    /// initializes a `PublicKeyCredentialDescriptor` from the AuthenticationServices one.
    /// - Parameter asDescriptor: The descriptor provides by AuthenticationServices.
    init(from asDescriptor: ASAuthorizationPublicKeyCredentialDescriptor) {
        self.init(
            ty: Constants.defaultFido2PublicKeyCredentialType,
            id: asDescriptor.credentialID,
            transports: nil,
        )
    }
}
