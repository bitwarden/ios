import BitwardenShared

// swiftlint:disable line_length

public extension WebAuthnAuthenticatorAttestationResponse {
    /// Fixture of the WebAuthn AuthenticatorAttestationResponse.
    /// The default values are realistic base64url-encoded data that conforms to the WebAuthn specification.
    /// - Parameters:
    ///   - attestationObject: base64url-encoded attestation object from the authenticator.
    ///     Default is a minimal CBOR-encoded attestation object.
    ///   - clientDataJSON: base64url-encoded JSON serialization of the client data.
    ///     Default represents a typical WebAuthn credential creation ceremony.
    /// - Returns: A test fixture instance of `WebAuthnAuthenticatorAttestationResponse`.
    static func fixture(
        attestationObject: String = "o2NmbXRkbm9uZWdhdHRTdG10oGhhdXRoRGF0YVikSZYN5YgOjGh0NBcPZHZgW4_krrmihjLHmVzzuoMdl2NFAAAAAK3OAAI1vMYKZIsLJfHwVQMAIIjM0h4PCZlhqM4VOXN7tXmGRhpZKLGZQMzQXLkPQVNJpQECAyYgASFYIIFdFdcLp3cDMTvPxKKPxAXRqPyFiLQZg2T4kRJWWF_OIlggWIvSfcAQa4MmTLNB4TNUQkNcEWPNUMmQYI5chz5U",
        clientDataJSON: String = "eyJ0eXBlIjoid2ViYXV0aG4uY3JlYXRlIiwiY2hhbGxlbmdlIjoiVDFSVlUxUkZVbE5mUTBoQlRFeEZUa2RGIiwib3JpZ2luIjoiaHR0cHM6Ly9leGFtcGxlLmNvbSIsImNyb3NzT3JpZ2luIjpmYWxzZX0",
    ) -> WebAuthnAuthenticatorAttestationResponse {
        .init(
            attestationObject: attestationObject,
            clientDataJSON: clientDataJSON,
        )
    }
}

// swiftlint:enable line_length
