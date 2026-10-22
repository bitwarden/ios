import BitwardenKit
import BitwardenResources
import Foundation

// MARK: - AgentAccessAutoApproveDuration

/// A length of time an approval can be remembered for, shown in the duration menu.
///
struct AgentAccessAutoApproveDuration: Equatable, Hashable, Identifiable, Menuable, Sendable {
    // MARK: Type Properties

    /// The durations the user can pick from.
    static var all: [AgentAccessAutoApproveDuration] {
        AgentAccessConstants.autoApproveDurationsMinutes.map(AgentAccessAutoApproveDuration.init)
    }

    // MARK: Properties

    /// The number of minutes.
    let minutes: Int

    var id: Int { minutes }

    var localizedName: String {
        Localizations.agentAccessAutoApproveMinutes(minutes)
    }
}

// MARK: - AgentAccessApprovalStatus

/// The status of the request shown by the `AgentAccessApprovalView`.
///
enum AgentAccessApprovalStatus: Equatable, Sendable {
    /// The request has expired or was already answered.
    case expired

    /// The request couldn't be loaded, so it can't be approved.
    case failed

    /// The request is being loaded.
    case loading

    /// The request is open and waiting for the user's answer.
    case pending
}

// MARK: - AgentAccessApprovalState

/// The state used to present the `AgentAccessApprovalView`.
///
struct AgentAccessApprovalState: Equatable, Sendable {
    // MARK: Properties

    /// The ID of the pending request.
    let requestId: String

    /// The number of minutes to remember the approval for.
    var autoApproveMinutes = AgentAccessConstants.defaultAutoApproveMinutes

    /// The vault logins the user can choose from.
    var candidates = [AgentAccessCandidate]()

    /// The 64 character identity fingerprint of the agent.
    var connectionFingerprint = ""

    /// The name of the agent connection, such as "Codex".
    var connectionName = ""

    /// The time the request stops being valid.
    var expiresAt: Date?

    /// Whether the approval is remembered for an identical request.
    var isAutoApproveOn = false

    /// What the agent asked for.
    var query: AgentAccessQuery?

    /// The number of seconds left to answer.
    var secondsRemaining: Int?

    /// The ID of the vault login the user selected.
    var selectedCipherId: String?

    /// The status of the request.
    var status = AgentAccessApprovalStatus.loading

    // MARK: Computed Properties

    /// Whether the user can approve the request.
    var canApprove: Bool {
        status == .pending && selectedCipherId != nil
    }

    /// The sentence that says who is asking for what.
    var descriptionText: String {
        Localizations.agentAccessApproveDescription(connectionName, query?.displayValue ?? "")
    }

    /// The beginning of the agent's fingerprint, shown so the user can recognize the agent.
    var fingerprintPrefix: String {
        String(connectionFingerprint.prefix(8))
    }
}
