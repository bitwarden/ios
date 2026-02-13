/// WebAuthn PRF input values.
///
/// For historical reasons, this is named with the Authentication prefix, even though it may be used on registration.
///
/// [Link to specification](https://www.w3.org/TR/webauthn-3/#dictdef-authenticationextensionsprfvalues)
struct WebAuthnAuthenticationExtensionsPRFValues: Codable, Equatable, Hashable, Sendable {
    /// A salt to use when evaluating the PRF.
    ///
    /// [Link to specification](https://www.w3.org/TR/webauthn-3/#dom-authenticationextensionsprfvalues-first)
    let first: String

    /// An additional salt to use when evaluating a second PRF output.
    ///
    /// [Link to specification](https://www.w3.org/TR/webauthn-3/#dom-authenticationextensionsprfvalues-second)
    let second: String?
}
