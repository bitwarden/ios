// MARK: - AgentAccessRoute

/// A route to specific screens in the Agent Access flow.
///
public enum AgentAccessRoute: Equatable, Hashable {
    /// A route to the approval sheet for a pending agent request.
    ///
    /// - Parameter requestId: The ID of the pending request to show.
    ///
    case approval(requestId: String)

    /// A route to the activity log.
    case auditLog

    /// A route that pops the current screen off the stack.
    case back

    /// A route to the list of paired agents.
    case connections

    /// A route to dismiss the screen currently presented modally.
    ///
    /// - Parameter action: The action to perform on dismiss.
    ///
    case dismiss(_ action: DismissAction? = nil)

    /// A route to the Agent Access home screen.
    case home

    /// A route to the screen that pairs a new agent.
    case pairing

    /// A route to the system share sheet for a piece of text.
    ///
    /// - Parameter text: The text to share.
    ///
    case share(text: String)
}
