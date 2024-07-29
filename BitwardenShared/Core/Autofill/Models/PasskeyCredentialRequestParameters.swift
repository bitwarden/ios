import AuthenticationServices

/// Protocol to bypass using @available for passkey request parameters and also to be able to do unit tests
/// given that we cannot create an instance of `ASPasskeyCredentialRequestParameters`.
public protocol PasskeyCredentialRequestParameters {
    /// A list of allowed credential IDs for this request. An empty list means all credentials are allowed.
    var allowedCredentials: [Data] { get }
    /// Hash of client data for credential provider to sign as part of the operation.
    var clientDataHash: Data { get }
    /// The relying party identifier for this request.
    var relyingPartyIdentifier: String { get }
    /// A preference for whether the authenticator should attempt to verify that it is being used by its owner,
    /// such as through a PIN or biometrics.
    var userVerificationPreference: ASAuthorizationPublicKeyCredentialUserVerificationPreference { get }
}

@available(iOSApplicationExtension 17.0, *)
extension ASPasskeyCredentialRequestParameters: PasskeyCredentialRequestParameters {}
