import Foundation

/// Encapsulates the state of a guided tour being shown on a view.
///
struct GuidedTourState: Equatable {
    /// The horizontal position of the arrow.
    var arrowHorizontalPosition: ArrowHorizontalPosition

    /// the padding of the card from the leading edge.
    var cardLeadingPadding: CGFloat?

    /// the padding of the card from the trailing edge.
    var cardTrailingPadding: CGFloat?

    /// Progress text (e.g. "1 OF 3") to show above title.
    var progressText: String {
        Localizations.stepOfStep(step, totalStep)
    }

    /// The current step in the guided tour.
    var step: Int

    /// The region of the view to spotlight.
    var spotlightRegion: CGRect

    /// The shape of the spotlight.
    var spotlightShape: SpotlightShape

    /// The corner radius of the spotlight.
    var spotlightCornerRadius: CGFloat?

    /// The total number of steps in the guided tour.
    var totalStep: Int

    /// The title of the guided tour card.
    var title: String
}

/// The shape of the spotlight.
///
enum SpotlightShape: Equatable {
    /// The spotlight is a circle.
    case circle

    /// The spotlight is a rectangle.
    case rectangle
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

/// extension for `GuidedTourState` to provide some common states.
extension GuidedTourState {
    /// The first step of the learn new login guided tour.
    static let loginStep1 = GuidedTourState(
        arrowHorizontalPosition: .center,
        cardLeadingPadding: 37,
        cardTrailingPadding: 11.56,
        step: 1,
        spotlightRegion: .zero,
        spotlightShape: .circle,
        totalStep: 3,
        title: Localizations.useThisButtonToGenerateANewUniquePassword
    )

    /// The second step of the learn new login guided tour.
    static let loginStep2 = GuidedTourState(
        arrowHorizontalPosition: .center,
        cardLeadingPadding: 24,
        cardTrailingPadding: 24,
        step: 2,
        spotlightRegion: .zero,
        spotlightShape: .rectangle,
        spotlightCornerRadius: 8,
        totalStep: 3,
        title: Localizations.loginGuidedTourStep2
    )

    /// The third step of the learn new login guided tour.
    static let loginStep3 = GuidedTourState(
        arrowHorizontalPosition: .center,
        cardLeadingPadding: 24,
        cardTrailingPadding: 24,
        step: 3,
        spotlightRegion: .zero,
        spotlightShape: .rectangle,
        spotlightCornerRadius: 8,
        totalStep: 3,
        title: Localizations.youMustAddAWebAddressToUseAutofillToAccessThisAccount
    )
}
