import Foundation

/// API response model for a user profile.
///
struct ProfileResponseModel: Codable, Equatable {
    // MARK: Properties

    /// The user's avatar color.
    let avatarColor: String?

    /// The user's locale.
    let culture: String?

    /// The user's email.
    let email: String?

    /// Whether the user's email is verified.
    let emailVerified: Bool

    /// Whether the user needs to reset their password.
    let forcePasswordReset: Bool

    /// The profile's identifier.
    let id: String

    /// The user's key.
    let key: String?

    /// The user's master password hint.
    let masterPasswordHint: String?

    /// The user's name.
    let name: String?

    /// A list of organizations that the user belongs to.
    let organizations: [ProfileOrganizationResponseModel]?

    /// Whether the user has a premium account.
    let premium: Bool

    /// Whether the user has a premium account from their organization.
    let premiumFromOrganization: Bool

    /// The user's private key.
    let privateKey: String?

    /// The user's security stamp.
    let securityStamp: String?

    /// Whether the user has two factor enabled.
    let twoFactorEnabled: Bool

    /// Whether the user uses key connector.
    let usesKeyConnector: Bool
}
