/// WebAuthn PRF input values.
///
/// For historical reasons, this is named with the Authentication prefix, even though it may be used on registration.
///
/// [Link to specification](https://www.w3.org/TR/webauthn-3/#dictdef-authenticationextensionsprfvalues)
struct WebAuthnAuthenticationExtensionsPRFValues: Codable, Equatable, Hashable {
    let first: String
    let second: String?
}
