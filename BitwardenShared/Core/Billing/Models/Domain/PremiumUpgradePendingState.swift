// MARK: - PremiumUpgradePendingState

/// The persisted state of a pending Premium upgrade for the active account.
///
enum PremiumUpgradePendingState: Equatable, Sendable {
    /// No Premium upgrade is currently pending for the active account.
    case none

    /// A Premium upgrade is pending for the active account.
    case pending
}
