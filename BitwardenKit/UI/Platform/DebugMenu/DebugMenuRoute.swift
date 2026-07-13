// MARK: - DebugMenuRoute

/// A route to specific screens in the` DebugMenuView`
public enum DebugMenuRoute: Equatable, Hashable {
    /// A route to the screen for adding a Fill Assist debug rule.
    case addFillAssistRule

    /// A route to dismiss the screen currently presented modally.
    case dismiss
}
