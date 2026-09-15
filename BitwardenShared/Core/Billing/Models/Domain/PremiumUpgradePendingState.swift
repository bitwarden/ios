// MARK: - PremiumUpgradePendingState

/// The persisted state of a pending Premium upgrade for the active account.
///
enum PremiumUpgradePendingState: Equatable, Sendable {
    /// No Premium upgrade is currently pending for the active account.
    case none

    /// A Premium upgrade is pending for the active account.
    ///
    /// - Parameter lastAttemptFailed: Whether the last sync attempt to resolve the pending
    ///   Premium upgrade failed.
    ///
    ///   Can be transiently wrong after a compound sync failure: if a sync persists data —
    ///   including a new last-sync time — before throwing on a later step, the background sync
    ///   watcher (`resolveOnEachNewSync(userId:)`) observes that last-sync-time change and
    ///   resolves the pending upgrade with `syncFailed: false`, unaware the sync it rode in on
    ///   actually failed. Nothing reads this associated value yet; revisit if that changes.
    ///
    case pending(lastAttemptFailed: Bool)
}
