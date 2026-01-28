/// WebAuthn PublicKeyCredentialRequestOptions.
struct WebAuthnPublicKeyCredentialRequestOptions: Codable, Equatable, Hashable {
    let allowCredentials: [WebAuthnPublicKeyCredentialDescriptor]?
    let challenge: String
    let extensions: WebAuthnAuthenticationExtensionsClientInputs?
    let rpId: String
    let timeout: Int?
}
