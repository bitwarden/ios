// MARK: - BillingRoute

/// A route to a screen in the billing flow.
///
enum BillingRoute: Equatable {
    /// A route to dismiss the view.
    case dismiss

    /// A route to the Premium plan screen.
    case premiumPlan(PremiumSubscription?)

    /// A route to the Premium upgrade screen.
    case premiumUpgrade

    /// A route to the Premium upgrade complete screen.
    case premiumUpgradeComplete

    /// A route to the Premium upgrade complete screen, presented as the sole content of a
    /// freshly-created modal (no `PremiumUpgradeView` shown first in this coordinator instance).
    /// Used when a Premium upgrade resolves outside of the upgrade screen itself — e.g. a
    /// "Sync Now" retry succeeding after the upgrade screen has already been dismissed.
    case premiumUpgradeCompleteStandalone
}
