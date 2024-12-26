// MARK: - TwoFactorNoticeRoute

/// A route to a specific screen in the No Two Factor notice.
public enum TwoFactorNoticeRoute: Equatable, Hashable {
    /// A route to dismiss the current screen.
    case dismiss

    /// A route to the email access screen.
    case emailAccess(allowDelay: Bool, emailAddress: String)

    /// A route to the screen to set up two-factor authentication.
    case setUpTwoFactor(allowDelay: Bool, emailAddress: String)
}
