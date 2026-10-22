import BitwardenResources

// MARK: - AgentAccessHomeState

/// An object that defines the current state of an `AgentAccessHomeView`.
///
struct AgentAccessHomeState: Equatable {
    // MARK: Properties

    /// The automatic approvals that are currently active.
    var autoApproveRules = [AgentAccessAutoApproveRule]()

    /// The number of paired agents.
    var connectionsCount = 0

    /// Whether the active account listens for agent requests.
    var isListeningEnabled = false

    /// The saved relay server address.
    var relayURL = ""

    /// The relay server address as the user is editing it.
    var relayURLInput = ""

    /// The error shown under the relay server field, if any.
    var relayURLErrorMessage: String?

    /// The connection status of the active account.
    var status = AgentAccessConnectionStatus.disabled

    // MARK: Computed Properties

    /// Whether the relay server field holds an address that differs from the saved one.
    var isRelayURLChanged: Bool {
        relayURLInput.trimmingCharacters(in: .whitespacesAndNewlines) != relayURL
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
