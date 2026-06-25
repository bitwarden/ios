import BitwardenKit
import Foundation

// MARK: - BillingStateService

/// A service that provides state management functionality around billing.
///
protocol BillingStateService { // sourcery: AutoMockable
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

    /// Returns whether the "subscription needs attention" action card should be shown for the
    /// active account. Reads from persisted state — no network call.
    ///
    /// - Returns: `true` if the card should be shown.
    ///
    func getSubscriptionAttentionCardVisible() async -> Bool

    /// Returns whether the "Upgraded to Premium" action card should be shown for the active account.
    ///
    /// - Returns: `true` if the card should be shown.
    ///
    func getUpgradedToPremiumActionCardVisible() async -> Bool

    /// Persists whether the "subscription needs attention" action card should be shown for the
    /// active account.
    ///
    /// - Parameter visible: Whether the card should be shown.
    ///
    func setSubscriptionAttentionCardVisible(_ visible: Bool) async throws
}

// MARK: - DefaultStateService

extension DefaultStateService: BillingStateService {
    func isPremiumUpgradeBannerDismissed() async -> Bool {
        do {
            return try await getPremiumUpgradeBannerDismissed()
        } catch {
            errorReporter.log(error: error)
            return false
        }
    }

    func isPremiumUpgradeEligible() async -> Bool {
        guard await !doesActiveAccountHavePremium() else { return false }

        // Check account age >= 7 days
        guard let account = try? await getActiveAccount(),
              let creationDate = account.profile.creationDate else { return false }
        return timeProvider.timeSince(creationDate) >= Constants.premiumUpgradeBannerAccountAge
    }
}
