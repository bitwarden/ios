import BitwardenKit
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

    /// The user's master password hint.
    let masterPasswordHint: String?

    /// The user's name.
    let name: String?

    /// A list of organizations that the user belongs to.
    let organizations: [ProfileOrganizationResponseModel]?

    /// A new organizations list including accepted-state members from the server-side flag.
    /// Falls back to `organizations` when absent.
    let organizationsNew: [ProfileOrganizationResponseModel]?

    /// Whether the user has a Premium account.
    let premium: Bool

    /// Whether the user has a Premium account from their organization.
    @DefaultFalse var premiumFromOrganization: Bool

    /// The user's private key.
    @available(*, deprecated, message: "Use accountKeys instead when possible") // TODO: PM-24659 remove
    let privateKey: String?

    /// A list of organizations that the user has access to via a provider relationship.
    let providerOrganizations: [ProfileProviderOrganizationResponseModel]?

    /// The user's security stamp.
    let securityStamp: String?

    /// Whether the user has two factor enabled.
    let twoFactorEnabled: Bool

    /// Whether the user uses key connector.
    @DefaultFalse var usesKeyConnector: Bool

    // MARK: Computed Properties

    /// The effective list of organizations for this profile.
    ///
    /// Prefers `organizationsNew` (accepted-state members) over the legacy `organizations` list,
    /// and coalesces `isProviderUser` by checking membership in `providerOrganizations`.
    /// Returns `nil` when neither list is present.
    var effectiveOrganizations: [ProfileOrganizationResponseModel]? {
        guard let rawOrganizations = organizationsNew ?? organizations else { return nil }

        let providerOrgIds = Set(providerOrganizations?.map(\.id) ?? [])
        guard !providerOrgIds.isEmpty else { return rawOrganizations }
        return rawOrganizations.map { org in
            guard providerOrgIds.contains(org.id) else { return org }
            var mutable = org
            mutable.isProviderUser = true
            return mutable
        }
    }
}
