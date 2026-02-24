/// WebAuthn relying party information.
///
/// Distinct from ``BitwardenSdk.PublicKeyCredentialRpEntity`` for serialization purposes.
///
/// [Link to specification](https://www.w3.org/TR/webauthn-3/#dictdef-publickeycredentialrpentity)
struct WebAuthnPublicKeyCredentialRpEntity: Codable, Equatable, Hashable, Sendable {
    /// A unique identifier for the relying party entity.
    ///
    /// [Link to specification](https://www.w3.org/TR/webauthn-3/#dom-publickeycredentialrpentity-id)
    let id: String

    /// A human-palatable name for the relying party.
    ///
    /// [Link to specification](https://www.w3.org/TR/webauthn-3/#dom-publickeycredentialentity-name)
    let name: String
}
