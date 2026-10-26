// MARK: - AgentAccessAuditLogEffect

/// Effects that can be processed by an `AgentAccessAuditLogProcessor`.
///
enum AgentAccessAuditLogEffect: Equatable {
    /// The view appeared and the activity needs to be loaded.
    case appeared
}
