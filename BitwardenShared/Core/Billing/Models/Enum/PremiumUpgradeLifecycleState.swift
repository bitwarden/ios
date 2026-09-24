// MARK: - PremiumUpgradeLifecycleState

/// An account's position in the Premium upgrade lifecycle.
///
/// Transitions:
/// - `.notPremium` → `.pending` when Stripe checkout completes, before the server has
///   reported the purchase.
/// - `.pending` → `.premium` when a later sync reports the purchased Premium.
///
/// `.pending` → `.notPremium` is deliberately absent: a checkout that never settles stays
/// pending indefinitely.
///
enum PremiumUpgradeLifecycleState: Equatable, Sendable {
    /// The account has no Premium subscription and no upgrade is in flight.
    case notPremium

    /// Stripe checkout completed but the server has not yet reported the account as Premium.
    case pending

    /// The account has Premium.
    case premium
}
