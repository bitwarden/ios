import BitwardenResources

// MARK: - AgentAccessAuditKind + LocalizedName

extension AgentAccessAuditKind {
    /// The localized description of what happened.
    var localizedName: String {
        switch self {
        case .connectionEstablished:
            Localizations.agentAccessAuditConnectionEstablished
        case .sessionRefreshed:
            Localizations.agentAccessAuditSessionRefreshed
        case .connectionRejected:
            Localizations.agentAccessAuditConnectionRejected
        case .connectionRevoked:
            Localizations.agentAccessAuditConnectionRevoked
        case .credentialRequested:
            Localizations.agentAccessAuditCredentialRequested
        case .credentialApproved:
            Localizations.agentAccessAuditCredentialApproved
        case .credentialAutoApproved:
            Localizations.agentAccessAuditCredentialAutoApproved
        case .credentialDenied:
            Localizations.agentAccessAuditCredentialDenied
        case .credentialExpired:
            Localizations.agentAccessAuditCredentialExpired
        }
    }
}

// MARK: - AgentAccessAuditLogState

/// An object that defines the current state of an `AgentAccessAuditLogView`.
///
struct AgentAccessAuditLogState: Equatable {
    // MARK: Properties

    /// The activity entries, newest first.
    var entries = [AgentAccessAuditEntry]()

    /// Whether the entries are still loading.
    var isLoading = true
}
