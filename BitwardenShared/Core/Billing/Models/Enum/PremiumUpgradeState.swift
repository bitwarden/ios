// MARK: - PremiumUpgradeState

/// An account's position in the Premium upgrade lifecycle.
///
/// Derived, never persisted: only the pending flag is stored
/// (`premiumUpgradePending_<userId>`), and Premium itself comes from the account profile and
/// the account's organizations. See `DefaultBillingService.premiumUpgradeState(userId:)` for
/// the derivation and the reasoning behind the order its inputs are checked in.
///
/// Transitions:
/// - `.notPremium` → `.pending` when Stripe checkout completes but the post-checkout sync
///   still reports the account as non-Premium.
/// - `.pending` → `.premium` when a later sync reports the purchased Premium.
/// - `.pending` → `.notPremium` only on logout, where the published state is reset directly
///   without touching the logged-out account's persisted flag.
///
enum PremiumUpgradeState: Equatable, Sendable {
    /// The account has no Premium subscription and no upgrade is in flight.
    case notPremium

    /// Stripe checkout completed but the server has not yet reported the account as Premium.
    case pending

    /// The account has Premium, from any source — personal subscription or organization grant.
    case premium
}
