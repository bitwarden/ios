import BitwardenSdk
import Foundation

// MARK: - ItemsRoute

/// A route to a specific screen or subscreen of the Token List
public enum ItemsRoute: Equatable, Hashable {
    /// A route to the add item screen.
    case addItem

    /// A route to the base token list screen.
    case list

    /// A route to the manual totp screen for setting up TOTP.
    case setupTotpManual
}

enum ItemsEvent {
    /// When the app should show the scan code screen.
    ///  Defaults to `.setupTotpManual` if camera is unavailable.
    case showScanCode
}
