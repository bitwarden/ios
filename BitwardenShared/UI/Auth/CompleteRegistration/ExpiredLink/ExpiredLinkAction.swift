// MARK: - ExpiredLinkAction

/// Actions that can be processed by a `ExpiredLinkProcessor`.
enum ExpiredLinkAction: Equatable {
    /// The dismiss button was tapped.
    case dismissTapped

    /// The log in button was tapped
    case logInTapped

    /// The restart registration button was tapped.
    case restartRegistrationTapped
}
