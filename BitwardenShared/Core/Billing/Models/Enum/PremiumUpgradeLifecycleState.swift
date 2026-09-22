// MARK: - PremiumUpgradeLifecycleState

/// An account's position in the Premium upgrade lifecycle.
///
/// Named for the lifecycle rather than the shorter `PremiumUpgradeState`, which is already the
/// `PremiumUpgradeView` processor state in `UI/Billing/PremiumUpgrade/`. Mirrors Android's
/// `UpgradeLifecycleState`.
///
/// Derived, never persisted: only the pending flag is stored
/// (`premiumUpgradePending_<userId>`), and Premium itself comes from the account profile and
/// the account's organizations. See `DefaultBillingService.premiumUpgradeLifecycleState(userId:)`
/// for the derivation and the reasoning behind the order its inputs are checked in.
///
/// Transitions:
/// - `.notPremium` → `.pending` when Stripe checkout completes but the post-checkout sync
///   still reports the account as non-Premium.
/// - `.pending` → `.premium` when a later sync reports the purchased Premium.
///
/// There is deliberately no `.pending` → `.notPremium` transition: a checkout that never
/// settles leaves the account pending indefinitely, matching Android, where the flag likewise
/// clears only on the personal-Premium transition.
///
enum PremiumUpgradeLifecycleState: Equatable, Sendable {
    /// The account has no Premium subscription and no upgrade is in flight.
    case notPremium

    /// Stripe checkout completed but the server has not yet reported the account as Premium.
    case pending

    /// The account has Premium, from any source — personal subscription or organization grant.
    case premium
}
