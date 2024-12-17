// MARK: - SetUpTwoFactorEffect

/// Effects that can be processed by a `SetUpTwoFactorProcessor`.
///
enum SetUpTwoFactorEffect: Equatable, Sendable {
    /// The user tapped the "remind me later" button.
    case remindMeLaterTapped
}
