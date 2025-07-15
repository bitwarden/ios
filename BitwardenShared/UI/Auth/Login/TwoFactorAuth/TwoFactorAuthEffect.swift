// MARK: - TwoFactorAuthEffect

/// Effects that can be processed by a `TwoFactorAuthProcessor`.
enum TwoFactorAuthEffect: Equatable {
    /// The two factor auth view appeared.
    case appeared

    /// Attempts to authenticate via Duo.
    case beginDuoAuth

    /// Attempts to authenticate via WebAuthn.
    case beginWebAuthn

    /// The continue button was tapped.
    case continueTapped

    /// The view appeared on screen.
    case listenForNFC

    /// The app received a DUO 2FA token.
    case receivedDuoToken(String)

    /// The resend email button was tapped.
    case resendEmailTapped

    /// The Yubikey try again button was tapped.
    case tryAgainTapped
}
