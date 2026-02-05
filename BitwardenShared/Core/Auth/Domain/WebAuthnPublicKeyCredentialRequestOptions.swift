/// WebAuthn PublicKeyCredentialRequestOptions.
///
/// [Link to specification](https://www.w3.org/TR/webauthn-3/#dictdef-publickeycredentialrequestoptions)
struct WebAuthnPublicKeyCredentialRequestOptions: Codable, Equatable, Hashable, Sendable {
    /// A list of credentials acceptable to the relying party.
    ///
    /// [Specification](https://www.w3.org/TR/webauthn-3/#dom-publickeycredentialrequestoptions-allowcredentials)
    let allowCredentials: [WebAuthnPublicKeyCredentialDescriptor]?

    /// A challenge that the authenticator signs, encoded in base64url.
    ///
    /// [Link to specification](https://www.w3.org/TR/webauthn-3/#dom-publickeycredentialrequestoptions-challenge)
    let challenge: String

    /// Additional parameters requesting additional processing by the client and authenticator.
    ///
    /// [Link to specification](https://www.w3.org/TR/webauthn-3/#dom-publickeycredentialrequestoptions-extensions)
    let extensions: WebAuthnAuthenticationExtensionsClientInputs?

    /// The relying party identifier.
    ///
    /// [Link to specification](https://www.w3.org/TR/webauthn-3/#dom-publickeycredentialrequestoptions-rpid)
    let rpId: String

    /// A time, in milliseconds, that the caller is willing to wait for the call to complete.
    ///
    /// [Link to specification](https://www.w3.org/TR/webauthn-3/#dom-publickeycredentialrequestoptions-timeout)
    let timeout: Int?
}
