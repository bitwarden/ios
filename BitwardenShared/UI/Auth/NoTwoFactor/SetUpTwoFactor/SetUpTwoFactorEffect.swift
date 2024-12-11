// MARK: - SetUpTwoFactorEffect

/// Effects that can be processed by a `SetUpTwoFactorProcessor`.
///
enum SetUpTwoFactorEffect: Equatable, Sendable {
    /// The set up two factor notice appeared on screen
    case appeared

    case turnOnTwoFactorTapped

    case changeAccountEmailTapped

    case remindMeLaterTapped
}
