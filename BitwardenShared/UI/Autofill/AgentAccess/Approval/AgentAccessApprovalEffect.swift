// MARK: - AgentAccessApprovalEffect

/// Effects that can be processed by an `AgentAccessApprovalProcessor`.
///
enum AgentAccessApprovalEffect: Equatable {
    /// Approve the request with the selected login, after verifying the user.
    case approve

    /// Deny the request.
    case deny

    /// Load the request and the logins that can answer it.
    case loadData

    /// Count down the time left to answer.
    case streamCountdown
}
