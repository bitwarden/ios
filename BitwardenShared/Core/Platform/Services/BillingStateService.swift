import BitwardenKit
import Foundation

// MARK: - BillingStateService

/// A service that provides state management functionality around billing.
///
protocol BillingStateService { // sourcery: AutoMockable
    // MARK: Premium Upgrade Banner

    /// Gets whether the Premium upgrade banner has been dismissed.
    ///
    /// - Parameter userId: The user ID associated with the Premium upgrade banner dismissed value.
    ///   Defaults to the active account if `nil`.
    /// - Returns: Whether the Premium upgrade banner has been dismissed.
    ///
    func getPremiumUpgradeBannerDismissed(userId: String?) async throws -> Bool

    /// Returns whether the Premium upgrade banner has been permanently dismissed by the user.
    ///
    /// - Returns: `true` if the user has dismissed the banner.
    ///
    func isPremiumUpgradeBannerDismissed() async -> Bool

    /// Returns whether the user meets the eligibility criteria for the Premium upgrade.
    ///
    /// - Returns: `true` if the user is eligible for the Premium upgrade.
    ///
    func isPremiumUpgradeEligible() async -> Bool

    /// Sets whether the Premium upgrade banner has been dismissed.
    ///
    /// - Parameters:
    ///   - dismissed: Whether the Premium upgrade banner has been dismissed.
    ///   - userId: The user ID associated with the Premium upgrade banner dismissed value.
    ///     Defaults to the active account if `nil`.
    ///
    func setPremiumUpgradeBannerDismissed(_ dismissed: Bool, userId: String?) async throws

    // MARK: Premium Upgrade Pending

    /// Returns whether the last sync attempt to confirm a pending Premium upgrade failed.
    ///
    /// - Parameter userId: The user ID of the account to check. Defaults to the active account if `nil`.
    /// - Returns: `true` if the last sync attempt failed.
    ///
    func getPremiumUpgradeLastSyncAttemptFailed(userId: String?) async throws -> Bool

    /// Returns whether a Premium upgrade is pending.
    ///
    /// - Parameter userId: The user ID of the account to check. Defaults to the active account if `nil`.
    /// - Returns: `true` if a Premium upgrade is pending.
    ///
    func getPremiumUpgradePending(userId: String?) async throws -> Bool

    /// Sets whether the last sync attempt to confirm a pending Premium upgrade failed.
    ///
    /// - Parameters:
    ///   - failed: Whether the last sync attempt failed.
    ///   - userId: The user ID of the account to update. Defaults to the active account if `nil`.
    ///
    func setPremiumUpgradeLastSyncAttemptFailed(_ failed: Bool, userId: String?) async throws

    /// Sets whether a Premium upgrade is pending.
    ///
    /// - Parameters:
    ///   - pending: Whether a Premium upgrade is pending.
    ///   - userId: The user ID of the account to update. Defaults to the active account if `nil`.
    ///
    func setPremiumUpgradePending(_ pending: Bool, userId: String?) async throws

    // MARK: Subscription Attention Card

    /// Returns whether the "subscription needs attention" action card should be shown for the
    /// active account.
    ///
    /// - Returns: `true` if the card should be shown.
    ///
    func getSubscriptionAttentionCardVisible() async throws -> Bool

    /// Persists whether the "subscription needs attention" action card should be shown for the
    /// active account.
    ///
    /// - Parameters:
    ///   - visible: Whether the card should be shown.
    ///
    func setSubscriptionAttentionCardVisible(_ visible: Bool) async throws

    // MARK: Upgraded to Premium Card

    /// Returns whether the "Upgraded to Premium" action card should be shown.
    ///
    /// - Parameter userId: The user ID of the account to check. Defaults to the active account if `nil`.
    /// - Returns: `true` if the card should be shown.
    ///
    func getUpgradedToPremiumActionCardVisible(userId: String?) async throws -> Bool

    /// Sets whether the "Upgraded to Premium" action card should be shown.
    ///
    /// - Parameters:
    ///   - visible: Whether the action card should be shown.
    ///   - userId: The user ID of the account to update. Defaults to the active account if `nil`.
    ///
    func setUpgradedToPremiumActionCardVisible(_ visible: Bool, userId: String?) async throws
}

extension BillingStateService {
    /// Gets whether the Premium upgrade banner has been dismissed for the active account.
    ///
    /// - Returns: Whether the Premium upgrade banner has been dismissed.
    ///
    func getPremiumUpgradeBannerDismissed() async throws -> Bool {
        try await getPremiumUpgradeBannerDismissed(userId: nil)
    }

    /// Returns whether the last sync attempt to confirm a pending Premium upgrade failed, for the
    /// active account.
    ///
    /// - Returns: `true` if the last sync attempt failed.
    ///
    func getPremiumUpgradeLastSyncAttemptFailed() async throws -> Bool {
        try await getPremiumUpgradeLastSyncAttemptFailed(userId: nil)
    }

    /// Returns whether a Premium upgrade is pending for the active account.
    ///
    /// - Returns: `true` if a Premium upgrade is pending.
    ///
    func getPremiumUpgradePending() async throws -> Bool {
        try await getPremiumUpgradePending(userId: nil)
    }

    /// Returns whether the "Upgraded to Premium" action card should be shown for the active account.
    ///
    /// - Returns: `true` if the card should be shown.
    ///
    func getUpgradedToPremiumActionCardVisible() async throws -> Bool {
        try await getUpgradedToPremiumActionCardVisible(userId: nil)
    }

    /// Sets whether the Premium upgrade banner has been dismissed for the active account.
    ///
    /// - Parameter dismissed: Whether the Premium upgrade banner has been dismissed.
    ///
    func setPremiumUpgradeBannerDismissed(_ dismissed: Bool) async throws {
        try await setPremiumUpgradeBannerDismissed(dismissed, userId: nil)
    }

    /// Sets whether the last sync attempt to confirm a pending Premium upgrade failed, for the
    /// active account.
    ///
    /// - Parameters:
    ///   - failed: Whether the last sync attempt failed.
    ///
    func setPremiumUpgradeLastSyncAttemptFailed(_ failed: Bool) async throws {
        try await setPremiumUpgradeLastSyncAttemptFailed(failed, userId: nil)
    }

    /// Sets whether a Premium upgrade is pending for the active account.
    ///
    /// - Parameters:
    ///   - pending: Whether a Premium upgrade is pending.
    ///
    func setPremiumUpgradePending(_ pending: Bool) async throws {
        try await setPremiumUpgradePending(pending, userId: nil)
    }

    /// Sets whether the "Upgraded to Premium" action card should be shown for the active account.
    ///
    /// - Parameters:
    ///   - visible: Whether the action card should be shown.
    ///
    func setUpgradedToPremiumActionCardVisible(_ visible: Bool) async throws {
        try await setUpgradedToPremiumActionCardVisible(visible, userId: nil)
    }
}
