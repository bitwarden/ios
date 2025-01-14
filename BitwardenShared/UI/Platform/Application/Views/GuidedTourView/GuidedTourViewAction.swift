/// Actions that can be handled by a processor of the `GuidedTourView`.
///
enum GuidedTourViewAction: Equatable, Sendable {
    /// The user has pressed the back button.
    case backPressed
    
    /// The user has pressed the dismiss button.
    case dismissPressed

    /// The user has pressed the done button.
    case donePressed

    /// The user has pressed the next button.
    case nextPressed
}
