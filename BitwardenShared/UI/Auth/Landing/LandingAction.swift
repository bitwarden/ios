// MARK: - LandingAction

/// Actions that can be processed by a `LandingProcessor`.
enum LandingAction: Equatable {
    /// The continue button was pressed.
    case continuePressed

    /// The create account button was pressed.
    case createAccountPressed

    /// The value for the email was changed.
    case emailChanged(String)

    /// A forwarded profile switcher action.
    case profileSwitcherAction(ProfileSwitcherAction)

    /// The region button was pressed.
    case regionPressed

    /// The value for the remember me toggle was changed.
    case rememberMeChanged(Bool)

    /// The toast was shown or hidden.
    case toastShown(Toast?)
}
