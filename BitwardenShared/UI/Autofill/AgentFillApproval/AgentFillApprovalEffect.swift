import BitwardenSdk

// MARK: - AgentFillApprovalEffect

/// Effects that can be processed by an `AgentFillApprovalProcessor`.
///
enum AgentFillApprovalEffect: Equatable {
    /// Approve the request with the selected item, after verifying the user.
    case approve

    /// Deny the request.
    ///
    /// - Parameter reason: The reason the user gave for denying the request, if any.
    ///
    case deny(reason: DenyReason?)

    /// Fetch and open the request.
    case loadData
}
