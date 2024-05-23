// MARK: - CompleteRegistrationAction

/// Actions that can be processed by a `CompleteRegistrationProcessor`.
///
enum CompleteRegistrationAction: Equatable {
    /// The `CompleteRegistrationView` was dismissed.
    case dismiss

    /// The user edited the password hint text field.
    case passwordHintTextChanged(String)

    /// The user edited the master password text field.
    case passwordTextChanged(String)

    /// The user edited the re-type password text field.
    case retypePasswordTextChanged(String)

    /// The toast was shown or hidden.
    case toastShown(Toast?)

    /// An action to toggle the data breach check.
    case toggleCheckDataBreaches(Bool)

    /// An action to toggle whether passwords in text fields are visible.
    case togglePasswordVisibility(Bool)
}
