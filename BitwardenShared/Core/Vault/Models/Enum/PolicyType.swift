/// An enum that describes the restrictions for a policy.
///
enum PolicyType: Int, Codable {
    /// Requires users to have 2fa enabled.
    case twoFactorAuthentication = 0

    /// Sets minimum requirements for master password complexity.
    case masterPassword = 1

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

    /// Activates autofill with page load on the browser extension.
    case activateAutofill = 11

    /// If enabled, the setting to "Unlock with Pin" is hidden.
    case removeUnlockWithPin = 14

    /// An unknown policy type.
    case unknown = -1

    // MARK: Initialization

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(RawValue.self)
        self = Self(rawValue: rawValue) ?? .unknown
    }
}
