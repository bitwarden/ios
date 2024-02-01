/// API response model for master password policies.
///
struct MasterPasswordPolicyResponseModel: Codable, Equatable {
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
