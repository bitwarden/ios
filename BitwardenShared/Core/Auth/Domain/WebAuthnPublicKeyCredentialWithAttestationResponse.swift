/// Fields corresponding to a WebAuthn PublicKeyCredential with an AuthenticatorAttestationResponse.
///
/// [Link to specification](https://www.w3.org/TR/webauthn-3/#iface-pkcredential)
struct WebAuthnPublicKeyCredentialWithAttestationResponse: Encodable, Equatable {
    let id: String
    let rawId: String
    let response: WebAuthnAuthenticatorAttestationResponse
    let type: String
    // We are currently not sending back any extension results to the server, so we are omitting this slot.
    // let clientExtensionsResults: [String: Any]
}
