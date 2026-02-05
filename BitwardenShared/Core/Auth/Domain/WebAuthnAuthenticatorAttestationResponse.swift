/// Fields corresponding to a WebAuthn AuthenticatorAttestationResponse.
///
/// [Link to specification](https://www.w3.org/TR/webauthn-3/#authenticatorattestationresponse)
struct WebAuthnAuthenticatorAttestationResponse: Codable, Equatable, Hashable, Sendable {
    /// Attestation object received from the authenticator, encoded in base64url.
    ///
    /// [Specification](https://www.w3.org/TR/webauthn-3/#dom-authenticatorattestationresponse-attestationobject)
    let attestationObject: String

    /// JSON object of Client Data used for the request.
    ///
    /// [Link to specification](https://www.w3.org/TR/webauthn-3/#dom-authenticatorresponse-clientdatajson)
    let clientDataJSON: String
}
