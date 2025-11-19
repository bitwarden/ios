import BitwardenResources

// MARK: - TutorialState

/// An object that defines the current state of a `TutorialView`.
///
struct TutorialState: Equatable {
    // MARK: Properties

    /// The text to use on the continue button
    var continueButtonText: String {
        switch page {
        case .intro, .qrScanner:
            Localizations.continue
        case .uniqueCodes:
            Localizations.getStarted
        }
    }

    /// If the current page is the last page
    var isLastPage: Bool {
        switch page {
        case .intro, .qrScanner:
            false
        case .uniqueCodes:
            true
        }
    }

    /// The current page number
    var page: TutorialPage = .intro
}

enum TutorialPage: Equatable {
    case intro
    case qrScanner
    case uniqueCodes
}
