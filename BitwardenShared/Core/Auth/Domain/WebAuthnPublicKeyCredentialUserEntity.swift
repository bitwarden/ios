/// WebAuthn user account parameters.
///
/// Distinct from ``BitwardenSdk.PublicKeyCredentialUserEntity`` for serialization purposes.
///
/// [Link to specification](https://www.w3.org/TR/webauthn-3/#dictdef-publickeycredentialuserentity)
struct WebAuthnPublicKeyCredentialUserEntity: Codable, Equatable, Hashable, Sendable {
    /// The user handle of the user account, encoded in base64url.
    ///
    /// [Link to specification](https://www.w3.org/TR/webauthn-3/#dom-publickeycredentialuserentity-id)
    let id: String

    /// A human-palatable identifier for the user account.
    ///
    /// [Link to specification](https://www.w3.org/TR/webauthn-3/#dom-publickeycredentialentity-name)
    let name: String
}
