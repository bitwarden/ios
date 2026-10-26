import BitwardenKit

// MARK: - AgentAccessPairingAction

/// Actions that can be processed by an `AgentAccessPairingProcessor`.
///
enum AgentAccessPairingAction: Equatable {
    /// The user said the code matches the one on the agent.
    case confirmFingerprint

    /// The connection name changed.
    case connectionNameChanged(String)

    /// The copy token button was tapped.
    case copyToken

    /// The pairing mode changed.
    case modeChanged(AgentAccessPairingMode)

    /// The user said the code does not match the one on the agent.
    case rejectFingerprint

    /// The share token button was tapped.
    case shareToken

    /// The toast was shown or dismissed.
    case toastShown(Toast?)

    /// The try again button was tapped.
    case tryAgain
}
