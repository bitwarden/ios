// MARK: - SyncWithBrowserEffect

/// Effects that can be processed by a `SyncWithBrowserProcessor`.
///
enum SyncWithBrowserEffect: Equatable, Sendable {
    /// The view appeared on screen.
    case appeared

    /// The user tapped the "Launch browser" button.
    case launchBrowserTapped
}
