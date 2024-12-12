import Foundation

// MARK: - TwoFactorDisplayState

/// An enum to track a user's status vis-à-vis the NoTwoFactor notice screen
enum TwoFactorNoticeDisplayState: Codable, Equatable {
    /// The user has seen the screen and indicated they can access their email.
    case canAccessEmail

    /// The user has not seen the screen.
    case hasNotSeen

    /// The user has seen the screen, at the indicated Date, and selected "remind me later".
    case seen(Date)
}

enum NoTwoFactorHelper {

}

