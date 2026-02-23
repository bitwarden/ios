/// WebAuthn parameters for credential generation.
///
/// Distinct from ``BitwardenSdk.PublicKeyCredentialParameters`` for serialization purposes.
///
/// [Link to specification](https://www.w3.org/TR/webauthn-3/#dictdef-publickeycredentialparameters)
struct WebAuthnPublicKeyCredentialParameters: Codable, Equatable, Hashable, Sendable {
    /// A COSEAlgorithmIdentifier specifying the cryptographic signature algorithm.
    ///
    /// [Link to specification](https://www.w3.org/TR/webauthn-3/#dom-publickeycredentialparameters-alg)
    let alg: Int

    /// The type of credential to be created.
    ///
    /// [Link to specification](https://www.w3.org/TR/webauthn-3/#dom-publickeycredentialparameters-type)
    let type: String
}
