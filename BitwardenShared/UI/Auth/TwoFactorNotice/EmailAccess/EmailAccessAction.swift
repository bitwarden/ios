// MARK: - EmailAccessAction

/// Actions that can be processed by a `EmailAccessProcessor`.
///
enum EmailAccessAction: Equatable, Sendable {
    /// The user changed the toggle for being able to access email.
    case canAccessEmailChanged(Bool)

    /// The url has been opened so clear the value in the state.
    case clearURL

    /// The user tapped the learn more button.
    case learnMoreTapped
}
