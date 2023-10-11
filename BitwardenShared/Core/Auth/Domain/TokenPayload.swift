import Foundation

/// Data model containing the fields of a parsed JWT token.
///
struct TokenPayload: Codable, Equatable {
    // MARK: Types

    /// Key names used for encoding and decoding.
    enum CodingKeys: String, CodingKey, Equatable {
        case authenticationMethodsReference = "amr"
        case email
        case emailVerified = "email_verified"
        case expirationTimeIntervalSince1970 = "exp"
        case hasPremium = "premium"
        case name
        case userId = "sub"
    }

    // MARK: Properties

    /// A list of the authentication methods used in the authentication.
    let authenticationMethodsReference: [String]

    /// The user's email.
    let email: String

    /// Whether the user's email has been verified.
    let emailVerified: Bool

    /// The expiration time, as the number of seconds since Unix epoch.
    let expirationTimeIntervalSince1970: Int

    /// Whether the user has a premium account.
    let hasPremium: Bool

    /// The user's name.
    let name: String?

    /// The user's identifier.
    let userId: String
}

extension TokenPayload {
    /// Whether the user is an external user.
    var isExternal: Bool {
        authenticationMethodsReference.contains("external")
    }

    /// The expiration date of the token.
    var expirationDate: Date {
        Date(timeIntervalSince1970: TimeInterval(expirationTimeIntervalSince1970))
    }
}
