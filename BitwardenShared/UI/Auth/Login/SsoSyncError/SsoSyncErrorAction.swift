// MARK: - SsoSyncErrorAction

/// Actions that can be processed by a `SsoSyncErrorProcessor`.
///
enum SsoSyncErrorAction: Equatable, Sendable {
    /// The url has been opened so clear the value in the state.
    case clearURL

    /// The user tapped the "Continue without syncing" button.
    case continueWithoutSyncingTapped
}
