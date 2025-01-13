// MARK: - SetUpTwoFactorEffect

/// Effects that can be processed by a `SetUpTwoFactorProcessor`.
///
enum SetUpTwoFactorEffect: Equatable, Sendable {
    /// The user tapped the button to change email.
    case changeAccountEmailTapped

    /// The user tapped the "remind me later" button.
    case remindMeLaterTapped

    /// The user tapped the button to turn on two-factor authentication.
    case turnOnTwoFactorTapped
}
