// MARK: - CreateAccountState

/// An object that defines the current state of a `CreateAccountView`.
///
struct CreateAccountState: Equatable {
    // MARK: Properties

    /// The text in the email text field.
    var emailText: String = ""

    /// Whether or not the check for data breaches toggle is on.
    var isCheckDataBreachesToggleOn: Bool = false

    /// Whether or not the terms and privacy toggle is on.
    var isTermsAndPrivacyToggleOn: Bool = false

    /// The text in the password hint text field.
    var passwordHintText: String = ""

    /// The text in the master password text field.
    var passwordText: String = ""

    /// The text in the re-type password text field.
    var retypePasswordText: String = ""
}
