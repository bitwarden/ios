// MARK: - CheckEmailAction

/// Actions that can be processed by a `CheckEmailProcessor`.
enum CheckEmailAction: Equatable {
    /// The dismiss button was tapped.
    case dismissTapped

    /// The go back button was tapped
    case goBackTapped

    /// The log in button was tapped
    case logInTapped
}
