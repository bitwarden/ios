// MARK: - SyncWithBrowserAction

/// Actions that can be processed by a `SyncWithBrowserProcessor`.
///
enum SyncWithBrowserAction: Equatable, Sendable {
    /// The url has been opened so clear the value in the state.
    case clearURL

    /// The user tapped the "Continue without syncing" button.
    case continueWithoutSyncingTapped
}
