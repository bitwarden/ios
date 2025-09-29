import BitwardenSdk
import SwiftUI

// MARK: - AuthenticatorItemRoute

/// A route to a screen for a specific item.
enum AuthenticatorItemRoute: Equatable {
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

    /// A route to edit an item.
    ///
    /// - Parameter authenticatorItemView: the `AuthenticatorItemView` to edit
    case editAuthenticatorItem(_ authenticatorItemView: AuthenticatorItemView)
}

enum AuthenticatorItemEvent {}
