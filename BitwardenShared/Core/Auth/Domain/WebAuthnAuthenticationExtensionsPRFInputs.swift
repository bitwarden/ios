// swiftlint:disable line_length

/// Input values for WebAuthn PRF extension.
///
/// For historical reasons, this is named with the "Authentication" prefix, even though it may be used on both authentication and registration.
///
/// [Link to specification](https://www.w3.org/TR/webauthn-3/#dictdef-authenticationextensionsprfinputs)
struct WebAuthnAuthenticationExtensionsPRFInputs: Codable, Equatable, Hashable {
    let eval: WebAuthnAuthenticationExtensionsPRFValues?
    let evalByCredential: [String: WebAuthnAuthenticationExtensionsPRFValues]?
}

// swiftlint:enable line_length
