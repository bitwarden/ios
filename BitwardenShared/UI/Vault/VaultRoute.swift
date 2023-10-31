import Foundation

// MARK: - VaultRoute

/// A route to a specific screen in the vault tab.
public enum VaultRoute: Equatable, Hashable {
    /// A route to the add item screen.
    case addItem

    /// A route to display the specified alert.
    ///
    /// - Parameter alert: The alert to display.
    case alert(_ alert: Alert)

    /// A route to the username/password generator screen.
    case generator

    /// A route to the vault list screen.
    case list

    /// A route to the camera screen for setting up TOTP.
    case setupTotpCamera

    /// A route to the view item screen.
    case viewItem // TODO: BIT-219 Add an associated type to pass the item to the screen
}
