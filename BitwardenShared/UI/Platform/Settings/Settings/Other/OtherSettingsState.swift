// MARK: - OtherSettingsState

/// An object that defines the current state of the `OtherSettingsView`.
///
struct OtherSettingsState {
    /// Whether the allow sync on refresh toggle is on.
    var isAllowSyncOnRefreshToggleOn: Bool = false

    /// Whether the connect to watch toggle is on.
    var isConnectToWatchToggleOn: Bool = false

    /// A toast message to show in the view.
    var toast: Toast?
}
