import AuthenticationServices

@testable import BitwardenShared

/// Mock of `ASPasskeyCredentialRequest` that allows to set `excludedCredentials`.
/// We need this because the `ASPasskeyCredentialRequest` doesn't have an init that allows
/// to set `excludedCredentials`.
@available(iOS 17.0, *)
class MockASPasskeyCredentialRequest: ASPasskeyCredentialRequest {
    // MARK: Properties

    /// The value of `excludedCredentials`.
    private var excludedCredentialsValue: [ASAuthorizationPlatformPublicKeyCredentialDescriptor]?

    override var excludedCredentials: [ASAuthorizationPlatformPublicKeyCredentialDescriptor]? {
        excludedCredentialsValue
    }

    // MARK: Methods

    /// Sets the `excludedCredentials` value.
    /// - Parameter value: The excluded credentials value.
    func setExcludedCredentials(_ credentials: [ASAuthorizationPlatformPublicKeyCredentialDescriptor]?) {
        excludedCredentialsValue = credentials
    }
}
