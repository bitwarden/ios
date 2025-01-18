import Foundation

/// Actions that can be handled by a processor of the `GuidedTourView`.
///
enum GuidedTourViewAction: Equatable, Sendable {
    /// The user has tapped the back button.
    case backTapped

    /// The user has tapped the dismiss button.
    case dismissTapped

    /// The user has tapped the done button.
    case doneTapped

    /// The user has tapped the next button.
    case nextTapped
}

/// Common actions that can be handled by a processor of the `GuidedTourView`.
///
enum GuidedTourAction: Equatable, Sendable {
    /// A region to be spotlit for step was rendered and is ready to have the spotlight drawn using the supplied frame.
    case didRenderViewToSpotlight(frame: CGRect, step: GuidedTourStep)

    /// The guided tour visibility was toggled.
    case toggleGuidedTourVisibilityChanged(Bool)
}
