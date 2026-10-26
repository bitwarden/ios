// MARK: - AgentAccessConnectionsAction

/// Actions that can be processed by an `AgentAccessConnectionsProcessor`.
///
enum AgentAccessConnectionsAction: Equatable {
    /// The revoke button was tapped for a connection.
    case revokePressed(AgentAccessConnection)
}
