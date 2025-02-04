import Foundation

/// Encapsulates the state of a guided tour step.
///
struct GuidedTourStepState: Equatable {
    /// The horizontal position of the arrow.
    var arrowHorizontalPosition: ArrowHorizontalPosition

    /// The padding of the card from the leading edge.
    var cardLeadingPadding: CGFloat = 24

    /// The padding of the card from the trailing edge.
    var cardTrailingPadding: CGFloat = 24

    /// The region of the view to spotlight.
    var spotlightRegion: CGRect = .zero

    /// The shape of the spotlight.
    var spotlightShape: SpotlightShape

    /// The title of the guided tour card.
    var title: String
}

/// The shape of the spotlight.
///
enum SpotlightShape: Equatable {
    /// The spotlight is a circle.
    case circle

    /// The spotlight is a rectangle with rounded corners.
    case rectangle(cornerRadius: CGFloat)
}

/// The horizontal position of the arrow.
enum ArrowHorizontalPosition {
    /// The arrow is horizontally positioned at the left side of the spotlight.
    /// The position is calculated by dividing the width of the spotlight by 3
    /// and placing the arrow at the center of the first part.
    case left

    /// The arrow is horizontally positioned at the center of spotlight.
    case center

    /// The arrow is horizontally positioned at the left side of the spotlight.
    /// The position is calculated by dividing the width of the spotlight by 3
    /// and placing the arrow at the center of the last part.
    case right
}

/// The vertical position of the coach mark.
enum CoachMarkVerticalPosition {
    /// The coach mark is positioned at the top of spotlight.
    case top

    /// The coach mark is positioned at the bottom of spotlight.
    case bottom
}

/// Common steps used by different guided tours.
///
enum GuidedTourStep: Int, Equatable {
    /// The first step of the guided tour.
    case step1

    /// The second step of the guided tour.
    case step2

    /// The third step of the guided tour.
    case step3

    /// The fourth step of the guided tour.
    case step4

    /// The fifth step of the guided tour.
    case step5

    /// The sixth step of the guided tour.
    case step6

    /// The identifier of the step.
    var id: String {
        "\(rawValue)"
    }
}
