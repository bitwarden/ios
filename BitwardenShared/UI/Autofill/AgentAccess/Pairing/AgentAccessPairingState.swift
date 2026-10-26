import BitwardenKit
import BitwardenResources

// MARK: - AgentAccessPairingMode

/// How the user wants to pair an agent.
///
enum AgentAccessPairingMode: Int, CaseIterable, Equatable, Hashable, Identifiable, Menuable, Sendable {
    /// A one-time token that is copied, shared or scanned.
    case token

    /// A short code that is typed into the agent.
    case code

    var id: Int { rawValue }

    /// The kind of pairing the repository creates for this mode.
    var kind: AgentAccessPairingKind {
        switch self {
        case .token: .psk
        case .code: .rendezvous
        }
    }

    var localizedName: String {
        switch self {
        case .token: Localizations.agentAccessToken
        case .code: Localizations.agentAccessCode
        }
    }
}

// MARK: - AgentAccessPairingPhase

/// The step of the pairing flow that the screen shows.
///
enum AgentAccessPairingPhase: Equatable, Sendable {
    /// The user is choosing a name and a pairing mode.
    case form

    /// The token or code is shown and the app waits for the agent.
    case waiting

    /// The user compares the code on the phone with the one the agent shows.
    case verifying(AgentAccessFingerprintVerification)

    /// The agent was paired.
    case paired(AgentAccessConnection)

    /// The user said the codes do not match.
    case rejected

    /// Pairing could not finish.
    case failed(message: String)
}

// MARK: - AgentAccessPairingState

/// An object that defines the current state of an `AgentAccessPairingView`.
///
struct AgentAccessPairingState: Equatable {
    // MARK: Properties

    /// The name the user gives the connection.
    var connectionName = Localizations.agentAccessDefaultConnectionName

    /// The way the user wants to pair.
    var mode = AgentAccessPairingMode.token

    /// The token or code that was created, if any.
    var pairing: AgentAccessPairing?

    /// The step of the flow that the screen shows.
    var phase = AgentAccessPairingPhase.form

    /// A toast to show.
    var toast: Toast?

    // MARK: Computed Properties

    /// Whether the user can start pairing.
    var canStartPairing: Bool {
        !connectionName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// The command the user can run in their agent to use the token.
    var exampleCommand: String? {
        guard let pairing, pairing.kind == .psk else { return nil }
        return "aac connect --token \(pairing.token) --domain example.com"
    }
}
