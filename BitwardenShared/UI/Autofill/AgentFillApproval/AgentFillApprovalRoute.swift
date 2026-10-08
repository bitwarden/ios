// MARK: - AgentFillApprovalRoute

/// A route to specific screens in the agent fill approval flow.
///
public enum AgentFillApprovalRoute: Equatable, Hashable {
    /// A route to the agent fill approval screen.
    ///
    /// - Parameter id: The ID of the approval request to show.
    ///
    case approval(id: String)

    /// A route to dismiss the screen currently presented modally.
    ///
    /// - Parameter action: The action to perform on dismiss.
    ///
    case dismiss(_ action: DismissAction? = nil)
}
