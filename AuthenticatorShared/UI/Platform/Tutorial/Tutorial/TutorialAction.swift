// MARK: - TutorialAction

/// Synchronous actions processed by a `TutorialProcessor`.
///
enum TutorialAction: Equatable {
    /// The user tapped the continue button.
    case continueTapped

    /// The user changed the page.
    case pageChanged(TutorialPage)

    /// The user tapped the skip button.
    case skipTapped
}
