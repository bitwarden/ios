// MARK: - TwoFactorAuthEffect

/// Effects that can be processed by a `TwoFactorAuthProcessor`.
enum TwoFactorAuthEffect: Equatable {
    /// The continue button was tapped.
    case continueTapped

    /// The resend email button was tapped.
    case resendEmailTapped
}
