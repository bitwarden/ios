import BitwardenKit
import Foundation

// MARK: - BillingStateService

/// A service that provides state management functionality around billing.
///
protocol BillingStateService { // sourcery: AutoMockable
    // MARK: Premium Upgrade Banner

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

    // MARK: Premium Upgrade Pending

    /// Returns whether the last sync attempt for a pending Premium upgrade failed for the
    /// active account.
    ///
    /// - Returns: `true` if the last sync attempt failed.
    ///
    func getPremiumUpgradeLastSyncAttemptFailed() async throws -> Bool

    /// Returns whether a Premium upgrade is pending for the active account.
    ///
    /// - Returns: `true` if a Premium upgrade is pending.
    ///
    func getPremiumUpgradePending() async throws -> Bool

    /// Sets whether the last sync attempt for a pending Premium upgrade failed for the active
    /// account.
    ///
    /// - Parameters:
    ///   - failed: Whether the last sync attempt failed.
    ///
    func setPremiumUpgradeLastSyncAttemptFailed(_ failed: Bool) async throws

    /// Sets whether a Premium upgrade is pending for the active account.
    ///
    /// - Parameters:
    ///   - pending: Whether a Premium upgrade is pending.
    ///
    func setPremiumUpgradePending(_ pending: Bool) async throws

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

    /// Returns whether the "Upgraded to Premium" action card should be shown for the active account.
    ///
    /// - Returns: `true` if the card should be shown.
    ///
    func getUpgradedToPremiumActionCardVisible() async throws -> Bool

    /// Sets whether the "Upgraded to Premium" action card should be shown for the active account.
    ///
    /// - Parameters:
    ///   - visible: Whether the action card should be shown.
    ///
    func setUpgradedToPremiumActionCardVisible(_ visible: Bool) async throws
}
