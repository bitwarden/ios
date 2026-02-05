/// WebAuthn Credential Descriptor.
///
/// Distinct from ``BitwardenSdk.PublicKeyCredentialDescriptor`` for deserialization purposes.
///
/// [Link to specification](https://www.w3.org/TR/webauthn-3/#dictionary-credential-descriptor)
struct WebAuthnPublicKeyCredentialDescriptor: Codable, Equatable, Hashable, Sendable {
    /// The credential ID, encoded in base64url.
    ///
    /// [Link to specification](https://www.w3.org/TR/webauthn-3/#dom-publickeycredentialdescriptor-id)
    let id: String

    /// The type of credential.
    ///
    /// [Link to specification](https://www.w3.org/TR/webauthn-3/#dom-publickeycredentialdescriptor-type)
    let type: String
}
