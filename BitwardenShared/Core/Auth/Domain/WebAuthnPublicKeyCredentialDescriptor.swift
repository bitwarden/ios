/// WebAuthn Credential Descriptor.
///
/// Distinct from ``BitwardenSdk.PublicKeyCredentialDescriptor`` for deserialization purposes.
///
/// [Link to specification](https://www.w3.org/TR/webauthn-3/#dictionary-credential-descriptor)
struct WebAuthnPublicKeyCredentialDescriptor: Codable, Equatable, Hashable {
    let type: String
    let id: String
}
