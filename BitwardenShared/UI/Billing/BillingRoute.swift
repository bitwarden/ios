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
}
