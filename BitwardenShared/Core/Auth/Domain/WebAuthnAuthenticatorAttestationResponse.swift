/// Fields corresponding to a WebAuthn AuthenticatorAttestationResponse.
///
/// [Link to specification](https://www.w3.org/TR/webauthn-3/#authenticatorattestationresponse)
public struct WebAuthnAuthenticatorAttestationResponse: Codable, Equatable, Hashable, Sendable {
    /// Attestation object received from the authenticator, encoded in base64url.
    ///
    /// [Specification](https://www.w3.org/TR/webauthn-3/#dom-authenticatorattestationresponse-attestationobject)
    public let attestationObject: String

    /// JSON object of Client Data used for the request.
    ///
    /// [Link to specification](https://www.w3.org/TR/webauthn-3/#dom-authenticatorresponse-clientdatajson)
    public let clientDataJSON: String

    /// Creates a new `WebAuthnAuthenticatorAttestationResponse` with the specified attestation data.
    ///
    /// - Parameters:
    ///   - attestationObject: The attestation object received from the authenticator, encoded in base64url format.
    ///     This contains the authenticator data and an attestation statement.
    ///   - clientDataJSON: The JSON-serialized client data for the credential creation request,
    ///     encoded in base64url format.
    ///     This contains information about the origin, challenge, and type of the WebAuthn ceremony.
    public init(attestationObject: String, clientDataJSON: String) {
        self.attestationObject = attestationObject
        self.clientDataJSON = clientDataJSON
    }
}
