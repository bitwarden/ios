/// Inputs for WebAuthn extensions used during authentication.
struct WebAuthnAuthenticationExtensionsClientInputs: Codable, Equatable, Hashable, Sendable {
    /// Input values for PRF extensions.
    let prf: WebAuthnAuthenticationExtensionsPRFInputs?
}
