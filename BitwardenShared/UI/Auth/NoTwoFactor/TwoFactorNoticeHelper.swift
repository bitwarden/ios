import Foundation

// MARK: - TwoFactorDisplayState

/// An enum to track a user's status vis-à-vis the NoTwoFactor notice screen
enum TwoFactorNoticeDisplayState: Codable, Equatable {
    /// The user has seen the screen and indicated they can access their email.
    case canAccessEmail

    /// The user has indicated they can access their email
    /// as specified by the Permanent mode of the notice
    case canAccessEmailPermanent

    /// The user has not seen the screen.
    case hasNotSeen

    /// The user has seen the screen, at the indicated Date, and selected "remind me later".
    case seen(Date)
}

// MARK: - TwoFactorNoticeHelper

/// A protocol for a helper object to handle deciding whether or not to display
/// the two-factor notice, and displaying it if so.
///
protocol TwoFactorNoticeHelper {
    ///
    func maybeShowTwoFactorNotice(

    ) async
}

// MARK: - DefaultTwoFactorNoticeHelper

/// A default implementation of `TwoFactorNoticeHelper`
///
@MainActor
class DefaultTwoFactorNoticeHelper: TwoFactorNoticeHelper {
    // MARK: Types

    typealias Services = HasErrorReporter

    func maybeShowTwoFactorNotice() async {
        
    }
}
