import Foundation

/// API response model for a profile organization.
///
struct ProfileOrganizationResponseModel: Codable, Equatable {
    // MARK: Properties

    /// Whether the user can access secrets manager.
    let accessSecretsManager: Bool

    /// Whether the profile organization is enabled.
    let enabled: Bool

    /// Whether the profile organization has family sponsorship available.
    let familySponsorshipAvailable: Bool

    /// The profile organization family sponsorship name.
    let familySponsorshipFriendlyName: String?

    /// The profile organization family sponsorship last sync date.
    let familySponsorshipLastSyncDate: Date?

    /// The profile organization family sponsorship name.
    let familySponsorshipToDelete: Bool?

    /// The profile organization family sponsorship name.
    let familySponsorshipValidUntil: Date?

    /// Whether the profile organization has public and private keys.
    let hasPublicAndPrivateKeys: Bool

    /// The profile organization's identifier.
    let id: String

    /// The profile organization's identifier.
    let identifier: String?

    /// The profile organization's key.
    let key: String?

    /// Whether key connector is enabled for the profile organization.
    let keyConnectorEnabled: Bool

    /// The key connector URL for the profile organization.
    let keyConnectorUrl: String?

    /// The maximum number of collections for the profile organization.
    let maxCollections: Int?

    /// The maximum storage amount for the profile organization.
    let maxStorageGb: Int?

    /// The profile organization's name.
    let name: String?

    /// The profile organization's permissions.
    let permissions: Permissions?

    /// The profile organization's plan product.
    let planProductType: Int?

    /// The profile organization's provider identifier.
    let providerId: String?

    /// The profile organization's provider name.
    let providerName: String?

    /// The profile organization's provider type.
    let providerType: Int?

    /// Whether the profile organization is enrolled.
    let resetPasswordEnrolled: Bool

    /// The profile organization's number of seats.
    let seats: Int?

    /// Whether the profile organization is self-hosted.
    let selfHost: Bool

    /// Whether the profile organization is SSO bound.
    let ssoBound: Bool

    /// The profile's organization's status.
    let status: OrganizationUserStatusType

    /// The profile's organization's type.
    let type: Int?

    /// Whether the profile organization uses 2FA.
    let use2fa: Bool

    /// Whether the profile organization uses the activate autofill policy.
    let useActivateAutofillPolicy: Bool

    /// Whether the profile organization uses the API.
    let useApi: Bool

    /// Whether the profile organization uses custom permissions.
    let useCustomPermissions: Bool

    /// Whether the profile organization uses directory.
    let useDirectory: Bool

    /// Whether the profile organization uses events.
    let useEvents: Bool

    /// Whether the profile organization uses groups.
    let useGroups: Bool

    /// Whether the profile organization uses key connector.
    let useKeyConnector: Bool

    /// Whether the profile organization uses policies.
    let usePolicies: Bool

    /// Whether the profile organization uses reset password.
    let useResetPassword: Bool

    /// Whether the profile organization uses SCIM.
    let useScim: Bool

    /// Whether the profile organization uses the secrets manager.
    let useSecretsManager: Bool

    /// Whether the profile organization uses SSO.
    let useSso: Bool

    /// Whether the profile organization uses TOTP.
    let useTotp: Bool

    /// The profile organization's user identifier.
    let userId: String?

    /// Whether the profile organization's users get premium.
    let usersGetPremium: Bool
}
