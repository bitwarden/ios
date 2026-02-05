/// Input values for WebAuthn PRF extension.
///
/// For historical reasons, this is named with the "Authentication" prefix,
/// even though it may be used on both authentication and registration.
///
/// [Link to specification](https://www.w3.org/TR/webauthn-3/#dictdef-authenticationextensionsprfinputs)
struct WebAuthnAuthenticationExtensionsPRFInputs: Codable, Equatable, Hashable, Sendable {
    /// One or two inputs on which to evaluate PRF. Not all authenticators support evaluating the PRFs during
    /// credential creation so outputs may, or may not, be provided.
    /// If not, then an assertion is needed in order to obtain the outputs.
    ///
    /// [Link to specification](https://www.w3.org/TR/webauthn-3/#dom-authenticationextensionsprfinputs-eval)
    let eval: WebAuthnAuthenticationExtensionsPRFValues?

    /// A record mapping base64url encoded credential IDs to PRF inputs to evaluate for that credential.
    /// Only applicable during assertions when allowCredentials is not empty.
    ///
    /// [Specification](https://www.w3.org/TR/webauthn-3/#dom-authenticationextensionsprfinputs-evalbycredential)
    let evalByCredential: [String: WebAuthnAuthenticationExtensionsPRFValues]?
}
