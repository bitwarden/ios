// MARK: - CreateAccountAction

/// Actions that can be processed by a `CreateAccountProcessor`.
///
enum CreateAccountAction: Equatable {
    /// The `CreateAccountView` was dismissed.
    case dismiss

    /// The user edited the email text field.
    case emailTextChanged(String)

    /// The user edited the password hint text field.
    case passwordHintTextChanged(String)

    /// The user edited the master password text field.
    case passwordTextChanged(String)

    /// The user edited the re-type password text field.
    case retypePasswordTextChanged(String)

    /// An action to toggle the data breach check.
    case toggleCheckDataBreaches(Bool)

    /// An action to toggle whether passwords in text fields are visible.
    case togglePasswordVisibility(Bool)

    /// An action to toggle the terms and privacy agreement.
    case toggleTermsAndPrivacy(Bool)
}
