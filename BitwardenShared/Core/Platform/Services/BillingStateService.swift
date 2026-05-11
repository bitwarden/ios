import BitwardenKit
import Foundation

// MARK: - BillingStateService

/// A service that provides state management functionality around billing.
///
protocol BillingStateService { // sourcery: AutoMockable
    /// Returns whether the premium upgrade banner has been permanently dismissed by the user.
    ///
    /// - Returns: `true` if the user has dismissed the banner.
    ///
    func isPremiumUpgradeBannerDismissed() async -> Bool

    /// Returns whether the user meets the eligibility criteria for the premium upgrade.
    ///
    /// - Returns: `true` if the user is eligible for the premium upgrade.
    ///
    func isPremiumUpgradeEligible() async -> Bool
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
