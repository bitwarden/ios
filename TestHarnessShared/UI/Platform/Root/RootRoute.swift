import Foundation

/// The routes for navigating within the home flow.
///
public enum RootRoute {
    /// A route to the card autofill form test screen.
    case cardAutofillForm

    /// A route to the create account form test screen.
    case createAccountForm


    /// A route to the date field picker showcase screen.
    case dateFieldPickerShowcase

    /// A route to the file share test screen.
    case fileShare

    /// A route to the create passkey test screen.
    case registerPasskey

    /// A route to the scenario picker home screen.
    case scenarioPicker

    /// A route to the simple login form test screen.
    case simpleLoginForm

    /// A route to the TOTP autofill form test screen.
    case totpAutofillForm
}
