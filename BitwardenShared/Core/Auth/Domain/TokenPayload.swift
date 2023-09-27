/// Data model containing the fields of a parsed JWT token.
///
struct TokenPayload: Codable, Equatable {
    // MARK: Types

    /// Key names used for encoding and decoding.
    enum CodingKeys: String, CodingKey, Equatable {
        case email
        case hasPremium = "premium"
        case name
        case userId = "sub"
    }

    // MARK: Properties

    /// The user's email.
    let email: String

    /// Whether the user has a premium account.
    let hasPremium: Bool

    /// The user's name.
    let name: String?

    /// The user's identifier.
    let userId: String
}
