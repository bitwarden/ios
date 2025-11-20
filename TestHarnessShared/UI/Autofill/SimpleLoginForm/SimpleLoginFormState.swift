import Foundation

/// The state for the simple login form test screen.
///
struct SimpleLoginFormState: Equatable {
    // MARK: Properties

    /// The title of the screen.
    var title: String = Localizations.simpleLoginForm

    /// The username field value.
    var username: String = ""

    /// The password field value.
    var password: String = ""
}
