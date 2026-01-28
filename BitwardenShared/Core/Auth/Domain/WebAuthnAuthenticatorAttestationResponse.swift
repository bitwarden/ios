/// Fields corresponding to a WebAuthn AuthenticatorAttestationResponse.
///
/// [Link to specification](https://www.w3.org/TR/webauthn-3/#authenticatorattestationresponse)
struct WebAuthnAuthenticatorAttestationResponse: Encodable, Equatable {
    /// Attestation object received from the authenticator, encoded in base64url.
    let attestationObject: String

    /// JSON object of Client Data used for the request.
    let clientDataJson: String
}
