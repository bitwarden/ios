// MARK: - SsoSyncErrorEffect

/// Effects that can be processed by a `SsoSyncErrorProcessor`.
///
enum SsoSyncErrorEffect: Equatable, Sendable {
    /// The view appeared on screen.
    case appeared

    /// The user tapped the "Launch browser" button.
    case launchBrowserTapped
}
