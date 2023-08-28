/// An enum that describes the restrictions for a policy.
///
enum PolicyType: Int, Codable {
    /// Requires users to have 2fa enabled.
    case twoFactorAuthentication = 0

    /// Sets minimum requirements for master password complexity.
    case masterPassword = 1 // swiftlint:disable:this inclusive_language

    /// Sets minimum requirements/default type for generated passwords/passphrases.
    case passwordGenerator = 2

    /// Allows users to only be apart of one organization.
    case onlyOrg = 3

    /// Requires users to authenticate with SSO.
    case requireSSO = 4

    /// Disables personal vault ownership for adding/cloning items.
    case personalOwnership = 5

    /// Disables the ability to create and edit Sends.
    case disableSend = 6

    /// Sets restrictions or defaults for Bitwarden Sends.
    case sendOptions = 7

    /// Allows orgs to use reset password : also can enable auto-enrollment during invite flow.
    case resetPassword = 8

    /// Sets the maximum allowed vault timeout.
    case maximumVaultTimeout = 9

    /// Disable personal vault export.
    case disablePersonalVaultExport = 10
}
