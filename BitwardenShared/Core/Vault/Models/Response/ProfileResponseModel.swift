import Foundation

/// API response model for a user profile.
///
struct ProfileResponseModel: Codable, Equatable, AccountKeysResponseModelProtocol {
    // MARK: Properties

    /// The user's account keys.
    let accountKeys: PrivateKeysResponseModel?

    /// The user's avatar color.
    let avatarColor: String?

    /// The user's account creation date.
    let creationDate: Date?

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
    @DefaultFalse var premiumFromOrganization: Bool

    /// The user's private key.
    @available(*, deprecated, message: "Use accountKeys instead when possible") // TODO: PM-24659 remove
    let privateKey: String?

    /// The user's security stamp.
    let securityStamp: String?

    /// Whether the user has two factor enabled.
    let twoFactorEnabled: Bool

    /// Whether the user uses key connector.
    @DefaultFalse var usesKeyConnector: Bool
}
