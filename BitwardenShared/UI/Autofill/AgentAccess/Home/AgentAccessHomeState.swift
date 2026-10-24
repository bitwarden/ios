import BitwardenResources
import Foundation
import UserNotifications

// MARK: - AgentAccessHomeState

/// An object that defines the current state of an `AgentAccessHomeView`.
///
struct AgentAccessHomeState: Equatable {
    // MARK: Properties

    /// The automatic approvals that are currently active.
    var autoApproveRules = [AgentAccessAutoApproveRule]()

    /// The number of paired agents.
    var connectionsCount = 0

    /// Whether the advanced section with the relay server is expanded.
    var isAdvancedExpanded = false

    /// Whether the active account listens for agent requests.
    var isListeningEnabled = false

    /// The notification authorization status of the app.
    var notificationAuthorization = UNAuthorizationStatus.authorized

    /// The saved relay server address.
    var relayURL = ""

    /// The relay server address as the user is editing it.
    var relayURLInput = ""

    /// The error shown under the relay server field, if any.
    var relayURLErrorMessage: String?

    /// The connection status of the active account.
    var status = AgentAccessConnectionStatus.disabled

    /// The URL to open externally.
    var url: URL?

    // MARK: Computed Properties

    /// Whether to warn that agent requests won't show while the app is in the background.
    var showNotificationsWarning: Bool {
        isListeningEnabled && !notificationAuthorization.allowsAlerts
    }

    /// Whether the relay server field holds an address that differs from the saved one.
    var isRelayURLChanged: Bool {
        relayURLInput.trimmingCharacters(in: .whitespacesAndNewlines) != relayURL
    }

    /// Whether the saved relay server address is not the default.
    var isCustomRelayURL: Bool {
        !relayURL.isEmpty && relayURL != AgentAccessConstants.defaultRelayURL
    }

    /// The text that describes the connection status.
    var statusText: String {
        switch status {
        case .disabled:
            Localizations.agentAccessStatusDisabled
        case .connecting:
            Localizations.agentAccessStatusConnecting
        case .listening:
            Localizations.agentAccessStatusListening
        case .reconnecting:
            Localizations.agentAccessStatusReconnecting
        case .failed:
            Localizations.agentAccessStatusFailed
        }
    }
}
