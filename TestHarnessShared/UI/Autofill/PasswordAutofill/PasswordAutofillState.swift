import Foundation

/// The state for the password autofill test screen.
///
struct PasswordAutofillState: Equatable {
    // MARK: Properties

    /// The title of the screen.
    var title: String = "Password Autofill"

    /// The username field value.
    var username: String = ""

    /// The password field value.
    var password: String = ""
}
