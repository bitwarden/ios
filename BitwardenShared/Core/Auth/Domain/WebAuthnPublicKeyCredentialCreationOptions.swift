// swiftlint:disable line_length

/// WebAuthn [PublicKeyCredentialCreationOptions](https://www.w3.org/TR/webauthn-3/#dictdef-publickeycredentialcreationoptions).
struct WebAuthnPublicKeyCredentialCreationOptions: Codable, Equatable, Hashable {
    /// A base64-encoded challenge that the authenticator signs, along with other data, when producing an attestation
    /// object for the newly created credential.
    ///
    /// ([Link to specification](https://www.w3.org/TR/webauthn-3/#dom-publickeycredentialcreationoptions-challenge))
    ///
    /// Note that the server sends this challenge as a padded base64 string, not as a unpadded base64url string as is
    /// used in most places in the WebAuthn spec.
    let challenge: String

    /// Credential IDs received from the server which should not appear on the authenticator used to complete the
    /// ceremony.
    ///
    /// ([Link to specification](https://www.w3.org/TR/webauthn-3/#dom-publickeycredentialcreationoptions-excludecredentials))
    let excludeCredentials: [WebAuthnPublicKeyCredentialDescriptor]?

    /// WebAuthn client extension inputs.
    ///
    /// ([Link to specification](https://www.w3.org/TR/webauthn-3/#dom-publickeycredentialcreationoptions-extensions)).
    let extensions: WebAuthnAuthenticationExtensionsClientInputs?

    /// Types of WebAuthn credentials that the server supports.
    ///
    /// ([Link to specification](https://www.w3.org/TR/webauthn-3/#dom-publickeycredentialcreationoptions-pubkeycredparams))
    let pubKeyCredParams: [WebAuthnPublicKeyCredentialParameters]

    /// Relying party information for the request.
    ///
    /// [Link to specification](https://www.w3.org/TR/webauthn-3/#dom-publickeycredentialcreationoptions-rp).
    let rp: WebAuthnPublicKeyCredentialRpEntity // swiftlint:disable:this identifier_name

    /// Time, in milliseconds, that the server is willing to wait for a response.
    ///
    /// [Link to specification](https://www.w3.org/TR/webauthn-3/#dom-publickeycredentialcreationoptions-timeout)
    let timeout: Int?

    /// Information about the user for whom the credential is being created.
    ///
    /// [Link to spec](https://www.w3.org/TR/webauthn-3/#dom-publickeycredentialcreationoptions-user).
    let user: WebAuthnPublicKeyCredentialUserEntity
}

// swiftlint:enable line_length
