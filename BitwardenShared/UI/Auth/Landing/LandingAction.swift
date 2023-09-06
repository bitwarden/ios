// MARK: - LandingAction

/// Actions that can be processed by a `LandingProcessor`.
enum LandingAction {
    /// The continue button was pressed.
    case continuePressed

    /// The create account button was pressed.
    case createAccountPressed

    /// The value for the email was changed.
    case emailChanged(String)

    /// The region button was pressed.
    case regionPressed

    /// The value for the remember me toggle was changed.
    case rememberMeChanged(Bool)
}
