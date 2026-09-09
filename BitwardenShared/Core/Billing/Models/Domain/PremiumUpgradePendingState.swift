// MARK: - PremiumUpgradePendingState

/// The persisted state of a pending Premium upgrade for the active account.
///
struct PremiumUpgradePendingState: Equatable, Sendable {
    // MARK: Properties

    /// Whether a Premium upgrade is currently pending.
    let isPending: Bool

    /// Whether the last sync attempt for the pending Premium upgrade failed.
    ///
    /// Can be transiently wrong after a compound sync failure: if a sync persists data —
    /// including a new last-sync time — before throwing on a later step, the background sync
    /// watcher (`reconcileOnEachNewSync(userId:)`) observes that last-sync-time change and
    /// resolves the pending upgrade with `syncFailed: false`, unaware the sync it rode in on
    /// actually failed. Nothing reads this property yet; revisit if that changes.
    let lastAttemptFailed: Bool
}
