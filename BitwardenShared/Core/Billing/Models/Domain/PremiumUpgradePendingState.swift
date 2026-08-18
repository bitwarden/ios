// MARK: - PremiumUpgradePendingState

/// The persisted state of a pending Premium upgrade for the active account.
///
struct PremiumUpgradePendingState: Equatable {
    // MARK: Properties

    /// Whether a Premium upgrade is currently pending.
    let isPending: Bool

    /// Whether the last sync attempt for the pending Premium upgrade failed.
    let lastAttemptFailed: Bool
}
