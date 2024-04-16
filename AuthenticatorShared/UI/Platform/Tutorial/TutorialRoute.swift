import Foundation

/// A route to a specific screen in the tutorial.
///
public enum TutorialRoute: Equatable, Hashable {
    /// A route that dismisses the tutorial.
    case dismiss

    /// A route to the tutorial.
    case tutorial
}
