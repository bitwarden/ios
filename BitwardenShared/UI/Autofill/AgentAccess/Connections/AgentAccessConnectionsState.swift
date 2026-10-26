// MARK: - AgentAccessConnectionsState

/// An object that defines the current state of an `AgentAccessConnectionsView`.
///
struct AgentAccessConnectionsState: Equatable {
    // MARK: Properties

    /// The paired agents.
    var connections = [AgentAccessConnection]()

    /// Whether the paired agents are still loading.
    var isLoading = true
}
