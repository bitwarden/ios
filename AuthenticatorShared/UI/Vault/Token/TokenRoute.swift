import BitwardenSdk
import SwiftUI

// MARK: - TokenRoute

/// A route to a screen for a specific token.
enum TokenRoute: Equatable {
    /// A route to display the specified alert.
    ///
    /// - Parameter alert: The alert to display.
    ///
    case alert(_ alert: Alert)

    /// A route to dismiss the screen currently presented modally.
    ///
    /// - Parameter action: The action to perform on dismiss.
    ///
    case dismiss(_ action: DismissAction? = nil)

    /// A route to edit a token.
    ///
    /// - Parameter token: the `Token` to edit
    case editToken(_ token: Token)

    /// A route to the view token screen.
    ///
    /// - Parameter id: The id of the token to display.
    ///
    case viewToken(id: String)
}

enum TokenEvent {}
