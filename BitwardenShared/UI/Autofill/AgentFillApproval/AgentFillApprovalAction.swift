// MARK: - AgentFillApprovalAction

/// Actions that can be processed by an `AgentFillApprovalProcessor`.
///
enum AgentFillApprovalAction: Equatable {
    /// Dismiss the screen.
    case dismiss

    /// An item was selected to be approved.
    case itemSelected(String)
}
