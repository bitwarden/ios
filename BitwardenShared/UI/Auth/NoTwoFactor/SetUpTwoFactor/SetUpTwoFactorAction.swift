// MARK: - SetUpTwoFactorAction

/// Actions that can be processed by a `SetUpTwoFactorProcessor`.
///
enum SetUpTwoFactorAction: Equatable, Sendable {
    /// The url has been opened so clear the value in the state.
    case clearURL

    case turnOnTwoFactorTapped

    case changeAccountEmailTapped

    case remindMeLaterTapped
}
