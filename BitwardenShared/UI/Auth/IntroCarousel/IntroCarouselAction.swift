// MARK: - IntroCarouselAction

/// Actions that can be processed by a `IntroCarouselProcessor`.
///
enum IntroCarouselAction: Equatable {
    /// The current page index has changed.
    case currentPageIndexChanged(Int)

    /// The log in button was tapped.
    case logIn
}
