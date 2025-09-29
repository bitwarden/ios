import BitwardenResources
import Foundation

/// An object that defines the current state of a `GuidedTourView`.
///
struct GuidedTourViewState: Equatable {
    /// The index of the current step.
    var currentIndex = 0

    /// The current state of the guided tour.
    var currentStepState: GuidedTourStepState {
        guidedTourStepStates[currentIndex]
    }

    /// The state of each step in the guided tour.
    var guidedTourStepStates: [GuidedTourStepState]

    /// Progress text (e.g. "1 OF 3") to show above title.
    var progressText: String {
        Localizations.stepOfStep(step, totalSteps)
    }

    /// The flag to show/hide guided tour.
    var showGuidedTour: Bool = false

    /// The spotlight region for the current step.
    var spotlightRegion: CGRect {
        currentStepState.spotlightRegion
    }

    /// the current step.
    var step: Int {
        currentIndex + 1
    }

    /// The total number of steps in the guided tour.
    var totalSteps: Int {
        guidedTourStepStates.count
    }
}

extension GuidedTourViewState {
    /// Updates the state of the guided tour view based on the given `GuidedTourViewAction`.
    ///
    /// - Parameter action: The action to process.
    ///
    mutating func updateStateForGuidedTourViewAction(_ action: GuidedTourViewAction) {
        switch action {
        case .backTapped:
            currentIndex -= 1
        case let .didRenderViewToSpotlight(frame, step):
            guidedTourStepStates[step.rawValue].spotlightRegion = frame
        case .dismissTapped, .doneTapped:
            showGuidedTour = false
        case .nextTapped:
            currentIndex += 1
        case let .toggleGuidedTourVisibilityChanged(show):
            showGuidedTour = show
        }
    }
}
