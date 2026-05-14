// MARK: - BillingRoute

/// A route to a screen in the billing flow.
///
enum BillingRoute: Equatable {
    /// A route to dismiss the view.
    case dismiss

    /// A route to the premium plan screen.
    case premiumPlan

    /// A route to the premium upgrade screen.
    case premiumUpgrade

    /// A route to the premium upgrade complete screen.
    case premiumUpgradeComplete
}
