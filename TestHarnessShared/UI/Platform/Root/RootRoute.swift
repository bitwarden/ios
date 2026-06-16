import Foundation

/// The routes for navigating within the home flow.
///
public enum RootRoute {
    /// A route to the create passkey test screen.
    case registerPasskey

    /// A route to the card autofill form test screen.
    case cardAutofillForm

    /// A route to the scenario picker home screen.
    case scenarioPicker

    /// A route to the simple login form test screen.
    case simpleLoginForm
}
