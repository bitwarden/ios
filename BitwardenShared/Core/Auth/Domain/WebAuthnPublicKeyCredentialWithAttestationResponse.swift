/// Fields corresponding to a WebAuthn PublicKeyCredential with an AuthenticatorAttestationResponse.
///
/// [Link to specification](https://www.w3.org/TR/webauthn-3/#iface-pkcredential)
struct WebAuthnPublicKeyCredentialWithAttestationResponse: Codable, Equatable, Hashable, Sendable {
    // This internal slot contains the results of processing client extensions requested by the Relying Party
    // upon the Relying Party’s invocation of either `navigator.credentials.create()` or navigator.credentials.get().
    //
    // [Link to specification](https://www.w3.org/TR/webauthn-3/#dom-publickeycredential-clientextensionsresults-slot)
    //
    // We are currently not sending back any extension results to the server, so we are omitting this field.
    // let clientExtensionsResults: [String: Any]

    /// The credential's identifier, encoded in base64url.
    ///
    /// [Link to specification](https://www.w3.org/TR/webauthn-3/#ref-for-dom-credential-id)
    let id: String

    /// The raw credential identifier, encoded in base64url.
    ///
    /// [Link to specification](https://www.w3.org/TR/webauthn-3/#ref-for-dom-publickeycredential-rawid)
    let rawId: String

    /// The authenticator's response to the client's request to create a public key credential.
    ///
    /// [Link to specification](https://www.w3.org/TR/webauthn-3/#dom-publickeycredential-response)
    let response: WebAuthnAuthenticatorAttestationResponse

    /// The credential's type.
    ///
    /// [Link to specification](https://www.w3.org/TR/webauthn-3/#dom-publickeycredential-type-slot)
    let type: String
}
