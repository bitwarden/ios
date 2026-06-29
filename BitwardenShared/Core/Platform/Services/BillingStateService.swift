import BitwardenKit
import Foundation

// MARK: - BillingStateService

/// A service that provides state management functionality around billing.
///
protocol BillingStateService { // sourcery: AutoMockable
    // MARK: Account Premium Status

    /// Returns whether the active account has access to Premium features, either personally or
    /// via an organization.
    ///
    /// - Returns: Whether the active account has access to Premium features.
    ///
    func doesActiveAccountHavePremium() async -> Bool

    /// Returns whether the active user account has Premium personally (i.e. Premium that the user
    /// purchased themselves), as opposed to Premium granted by an organization.
    ///
    /// - Returns: Whether the active account has Premium personally.
    ///
    func doesActiveAccountHavePremiumPersonally() async -> Bool

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
