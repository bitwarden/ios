/// WebAuthn relying party information.
///
/// Distinct from ``BitwardenSdk.PublicKeyCredentialRpEntity`` for serialization purposes.
///
/// [Link to specification](https://www.w3.org/TR/webauthn-3/#dictdef-publickeycredentialrpentity)
struct WebAuthnPublicKeyCredentialRpEntity: Codable, Equatable, Hashable {
    let id: String
    let name: String
}
