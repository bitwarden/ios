import BitwardenKit
import Foundation
import UserNotifications

// MARK: - OtherSettingsState

/// An object that defines the current state of the `OtherSettingsView`.
///
struct OtherSettingsState {
    // MARK: Properties

    /// The time after which the clipboard should clear.
    var clearClipboardValue: ClearClipboardValue = .never

    /// Whether the allow sync on refresh toggle is on.
    var isAllowSyncOnRefreshToggleOn: Bool = false

    /// Indicates whether the Universal Clipboard toggle is on.
    var isAllowUniversalClipboardToggleOn: Bool = false

    /// Whether Agent Access is available and turned on for the active account.
    var isAgentAccessEnabled: Bool = false

    /// Whether the connect to watch toggle is on.
    var isConnectToWatchToggleOn: Bool = false

    /// Whether Siri & Shortcuts access toggle is on.
    var isSiriAndShortcutsAccessToggleOn: Bool = false

    /// The date of the last vault sync.
    var lastSyncDate: Date?

    /// The notification authorization status of the app.
    var notificationAuthorization = UNAuthorizationStatus.authorized

    /// A toast message to show in the view.
    var toast: Toast?

    /// The URL to open externally.
    var url: URL?

    /// Whether the connect to watch toggle should be shown.
    var shouldShowConnectToWatchToggle: Bool = false

    // MARK: Computed Properties

    /// Whether to warn that agent requests won't show while the app is in the background.
    var showAgentAccessNotificationsWarning: Bool {
        isAgentAccessEnabled && !notificationAuthorization.allowsAlerts
    }
}
