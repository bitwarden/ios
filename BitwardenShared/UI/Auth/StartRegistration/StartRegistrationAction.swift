// MARK: - StartRegistrationAction

/// Actions that can be processed by a `StartRegistrationProcessor`.
///
enum StartRegistrationAction: Equatable {
    /// The user edited the email text field.
    case emailTextChanged(String)

    /// The start registration appeared on screen.
    case disappeared

    /// The `StartRegistrationView` was dismissed.
    case dismiss

    /// The user edited the name text field.
    case nameTextChanged(String)

    /// The toast was shown or hidden.
    case toastShown(Toast?)

    /// An action to toggle the terms and privacy agreement.
    case toggleReceiveMarketing(Bool)
}
