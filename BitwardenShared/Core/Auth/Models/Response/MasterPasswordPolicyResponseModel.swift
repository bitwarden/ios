/// API response model for master password policies.
///
struct MasterPasswordPolicyResponseModel: Codable, Equatable {
    // MARK: Types

    /// Key names used for encoding and decoding.
    enum CodingKeys: String, CodingKey {
        case enforceOnLogin = "EnforceOnLogin"
        case minComplexity = "MinComplexity"
        case minLength = "MinLength"
        case requireLower = "RequireLower"
        case requireNumbers = "RequireNumbers"
        case requireSpecial = "RequireSpecial"
        case requireUpper = "RequireUpper"
    }

    // MARK: Properties

    /// Whether the policy needs to be enforced on login.
    let enforceOnLogin: Bool?

    /// The minimum required password complexity.
    let minComplexity: UInt8?

    /// The minimum required password length.
    let minLength: UInt8?

    /// Whether the password requires a lowercase character.
    let requireLower: Bool?

    /// Whether the password requires a number.
    let requireNumbers: Bool?

    /// Whether the password requires a special character.
    let requireSpecial: Bool?

    /// Whether the password requires an uppercase character.
    let requireUpper: Bool?
}
