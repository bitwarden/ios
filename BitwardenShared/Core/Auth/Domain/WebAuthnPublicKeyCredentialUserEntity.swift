/// WebAuthn user account parameters.
///
/// Distinct from ``BitwardenSdk.PublicKeyCredentialUserEntity`` for serialization purposes.
///
/// [Link to specification](https://www.w3.org/TR/webauthn-3/#dictdef-publickeycredentialuserentity)
struct WebAuthnPublicKeyCredentialUserEntity: Codable, Equatable, Hashable {
    let id: String
    let name: String
}
