// MARK: - SyncWithBrowserEffect

/// Effects that can be processed by a `SyncWithBrowserProcessor`.
///
enum SyncWithBrowserEffect: Equatable, Sendable {
    /// The user tapped the "Launch browser" button.
    case launchBrowserTapped
}
