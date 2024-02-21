// MARK: - TwoFactorAuthEffect

/// Effects that can be processed by a `TwoFactorAuthProcessor`.
enum TwoFactorAuthEffect: Equatable {
    /// The continue button was tapped.
    case continueTapped

    /// The view appeared on screen.
    case listenForNFC

    /// The resend email button was tapped.
    case resendEmailTapped
}
