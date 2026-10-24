// MARK: - AgentAccessHomeAction

/// Actions that can be processed by an `AgentAccessHomeProcessor`.
///
enum AgentAccessHomeAction: Equatable {
    /// The advanced section was expanded or collapsed.
    case advancedPressed

    /// The activity row was tapped.
    case auditLogPressed

    /// The connections row was tapped.
    case connectionsPressed

    /// The pair an agent row was tapped.
    case pairPressed

    /// The relay server text changed.
    case relayURLChanged(String)
}
