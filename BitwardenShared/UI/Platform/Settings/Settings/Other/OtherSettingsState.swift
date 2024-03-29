import Foundation

// MARK: - OtherSettingsState

/// An object that defines the current state of the `OtherSettingsView`.
///
struct OtherSettingsState {
    /// The time after which the clipboard should clear.
    var clearClipboardValue: ClearClipboardValue = .never

    /// Whether the allow sync on refresh toggle is on.
    var isAllowSyncOnRefreshToggleOn: Bool = false

    /// Whether the connect to watch toggle is on.
    var isConnectToWatchToggleOn: Bool = false

    /// The date of the last vault sync.
    var lastSyncDate: Date?

    /// The URL of the feedback webpage.
    var url: URL?

    /// A toast message to show in the view.
    var toast: Toast?
}
