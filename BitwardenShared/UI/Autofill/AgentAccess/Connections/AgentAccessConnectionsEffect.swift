// MARK: - AgentAccessConnectionsEffect

/// Effects that can be processed by an `AgentAccessConnectionsProcessor`.
///
enum AgentAccessConnectionsEffect: Equatable {
    /// The view appeared and the paired agents need to be loaded.
    case appeared
}
