import Foundation

// MARK: - OrganizationUserNotificationBannerData

/// Data for displaying the organization user notification banner, derived from the
/// `organizationUserNotification` policy.
///
struct OrganizationUserNotificationBannerData: Equatable {
    // MARK: Properties

    /// When non-nil, display a labelled dismiss button with this text instead of the default X button.
    let buttonText: String?

    /// The body text of the banner.
    let description: String

    /// Optional header text for the banner.
    let headerText: String?

    /// The revision date of the policy backing this banner, sourced from `Policy.revisionDate`.
    /// Used to identify the banner so that a previously dismissed banner reappears when the
    /// organization publishes an updated one.
    let revisionDate: Date?

    /// When `true`, re-show the banner on every login.
    let showAfterEveryLogin: Bool
}
