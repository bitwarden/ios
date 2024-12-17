// MARK: - TwoFactorNoticeRoute

/// A route to a specific screen in the No Two Factor notice.
public enum TwoFactorNoticeRoute: Equatable, Hashable {
    /// A route to dismiss the screen currently presented modally.
    case dismiss

    /// A route to the email access screen.
    case emailAccess

    /// A route to the screen to set up two-factor authentication.
    case setUpTwoFactor
}
