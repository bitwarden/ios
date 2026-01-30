/// WebAuthn parameters for credential generation.
///
/// Distinct from ``BitwardenSdk.PublicKeyCredentialParameters`` for serialization purposes.
///
/// [Link to specification](https://www.w3.org/TR/webauthn-3/#dictdef-publickeycredentialparameters)
struct WebAuthnPublicKeyCredentialParameters: Codable, Equatable, Hashable {
    let type: String
    let alg: Int
}
