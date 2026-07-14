// MARK: - DebugMenuRoute

/// A route to specific screens in the` DebugMenuView`
public enum DebugMenuRoute: Equatable, Hashable {
    /// A route to the screen for adding a Fill Assist debug rule.
    case addFillAssistRule

    /// A route to dismiss the screen currently presented modally.
    case dismiss

    /// A route to dismiss the Add Fill Assist debug rule screen without signaling that the
    /// debug menu itself was dismissed.
    case dismissAddFillAssistRule
}
