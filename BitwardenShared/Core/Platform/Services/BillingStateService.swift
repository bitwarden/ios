import BitwardenKit
import Foundation

// MARK: - BillingStateService

/// A service that provides state management functionality around billing.
///
protocol BillingStateService { // sourcery: AutoMockable
    // MARK: Premium Upgrade Banner

    /// Gets whether the Premium upgrade banner has been dismissed.
    ///
    /// - Parameters:
    ///   - userId: The user ID associated with the Premium upgrade banner dismissed value.
    ///     Defaults to the active account if `nil`.
    /// - Returns: Whether the Premium upgrade banner has been dismissed.
    ///
    func getPremiumUpgradeBannerDismissed(userId: String?) async throws -> Bool

    /// Sets whether the Premium upgrade banner has been dismissed.
    ///
    /// - Parameters:
    ///   - dismissed: Whether the Premium upgrade banner has been dismissed.
    ///   - userId: The user ID associated with the Premium upgrade banner dismissed value.
    ///     Defaults to the active account if `nil`.
    ///
    func setPremiumUpgradeBannerDismissed(_ dismissed: Bool, userId: String?) async throws

    // MARK: Premium Upgrade Eligibility

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

// MARK: - BillingStateService Convenience Methods

extension BillingStateService {
    /// Gets whether the Premium upgrade banner has been dismissed for the active account.
    ///
    /// - Returns: Whether the Premium upgrade banner has been dismissed.
    ///
    func getPremiumUpgradeBannerDismissed() async throws -> Bool {
        try await getPremiumUpgradeBannerDismissed(userId: nil)
    }

    /// Sets whether the Premium upgrade banner has been dismissed for the active account.
    ///
    /// - Parameters:
    ///   - dismissed: Whether the Premium upgrade banner has been dismissed.
    ///
    func setPremiumUpgradeBannerDismissed(_ dismissed: Bool) async throws {
        try await setPremiumUpgradeBannerDismissed(dismissed, userId: nil)
    }
}
