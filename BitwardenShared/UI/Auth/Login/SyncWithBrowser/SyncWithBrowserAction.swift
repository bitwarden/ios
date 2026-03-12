// MARK: - SyncWithBrowserAction

/// Actions that can be processed by a `SyncWithBrowserProcessor`.
///
enum SyncWithBrowserAction: Equatable, Sendable {
    /// The user tapped the "Continue without syncing" button.
    case continueWithoutSyncingTapped
}
