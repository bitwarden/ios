/// Fields corresponding to a WebAuthn PublicKeyCredential with an AuthenticatorAttestationResponse.
///
/// [Link to specification](https://www.w3.org/TR/webauthn-3/#iface-pkcredential)
public struct WebAuthnPublicKeyCredentialWithAttestationResponse: Codable, Equatable, Hashable, Sendable {
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
    public let id: String

    /// The raw credential identifier, encoded in base64url.
    ///
    /// [Link to specification](https://www.w3.org/TR/webauthn-3/#ref-for-dom-publickeycredential-rawid)
    public let rawId: String

    /// The authenticator's response to the client's request to create a public key credential.
    ///
    /// [Link to specification](https://www.w3.org/TR/webauthn-3/#dom-publickeycredential-response)
    public let response: WebAuthnAuthenticatorAttestationResponse

    /// The credential's type.
    ///
    /// [Link to specification](https://www.w3.org/TR/webauthn-3/#dom-publickeycredential-type-slot)
    public let type: String

    /// Creates a new `WebAuthnPublicKeyCredentialWithAttestationResponse` representing a public key credential
    /// created during a WebAuthn registration ceremony.
    ///
    /// - Parameters:
    ///   - id: The credential's identifier, encoded in base64url format. This is used by the relying party
    ///     to identify the credential in future authentication ceremonies.
    ///   - rawId: The raw credential identifier, encoded in base64url format. This is the same as `id` but
    ///     may be used in contexts where the raw binary form is needed.
    ///   - response: The authenticator's attestation response containing the attestation object and client data.
    ///     This provides cryptographic proof that the credential was created by a particular authenticator.
    ///   - type: The credential's type. This should typically be `"public-key"` for WebAuthn credentials.
    public init(
        id: String,
        rawId: String,
        response: WebAuthnAuthenticatorAttestationResponse,
        type: String,
    ) {
        self.id = id
        self.rawId = rawId
        self.response = response
        self.type = type
    }
}
