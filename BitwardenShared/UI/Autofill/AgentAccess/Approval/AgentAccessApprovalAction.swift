// MARK: - AgentAccessApprovalAction

/// Actions that can be processed by an `AgentAccessApprovalProcessor`.
///
enum AgentAccessApprovalAction: Equatable {
    /// The user changed how long the approval is remembered.
    case autoApproveMinutesChanged(Int)

    /// The user turned remembering the approval on or off.
    case autoApproveToggled(Bool)

    /// The user closed the screen.
    case dismiss

    /// A vault login was selected.
    case itemSelected(String)
}
