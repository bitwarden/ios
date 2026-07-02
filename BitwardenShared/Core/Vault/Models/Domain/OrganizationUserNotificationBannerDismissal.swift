import Foundation

// MARK: - OrganizationUserNotificationBannerDismissal

/// A persisted record of a user dismissing the organization user notification banner.
///
/// The banner reappears when:
/// - the organization publishes an updated banner (a different `revisionDate`), or
/// - the user logs out and back in, subject to `showAfterEveryLogin` and the logout type:
///   - a hard logout (user-initiated) always clears the record, so the banner reappears regardless, and
///   - a soft logout (e.g. vault-timeout logout) clears the record only when `showAfterEveryLogin` is `true`.
///
struct OrganizationUserNotificationBannerDismissal: Codable, Equatable {
    /// The revision date of the policy that was dismissed, used to detect when a newer banner is published.
    let revisionDate: Date?

    /// Whether the dismissed banner is configured to reappear after every login.
    let showAfterEveryLogin: Bool
}
