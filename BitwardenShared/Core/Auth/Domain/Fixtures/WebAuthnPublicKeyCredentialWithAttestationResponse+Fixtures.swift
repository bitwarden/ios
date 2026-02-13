import BitwardenShared

public extension WebAuthnPublicKeyCredentialWithAttestationResponse {
    /// Fixture of the WebAuthn PublicKeyCredential with an AuthenticatorAttestationResponse.
    /// The default values are realistic base64url-encoded data that conforms to the WebAuthn specification.
    /// - Parameters:
    ///   - id: The credential's identifier, encoded in base64url. Default is a realistic credential ID.
    ///   - rawId: The raw credential identifier, encoded in base64url. Default matches the `id` parameter.
    ///   - response: The authenticator's attestation response. Default uses the fixture from
    ///     `WebAuthnAuthenticatorAttestationResponse`.
    ///   - type: The credential's type. Default is `"public-key"` as specified by the WebAuthn standard.
    /// - Returns: A test fixture instance of `WebAuthnPublicKeyCredentialWithAttestationResponse`.
    static func fixture(
        id: String = "iMzSHg8JmWGozhU5c3u1eYZGGlkosZlAzNBcuQ9BU0k",
        rawId: String = "iMzSHg8JmWGozhU5c3u1eYZGGlkosZlAzNBcuQ9BU0k",
        response: WebAuthnAuthenticatorAttestationResponse = .fixture(),
        type: String = "public-key",
    ) -> WebAuthnPublicKeyCredentialWithAttestationResponse {
        .init(
            id: id,
            rawId: rawId,
            response: response,
            type: type,
        )
    }
}
