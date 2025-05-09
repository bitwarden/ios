// MARK: - LandingAction

/// Actions that can be processed by a `LandingProcessor`.
enum LandingAction: Equatable {
    /// The create account button was pressed.
    case createAccountPressed

    /// The value for the email was changed.
    case emailChanged(String)

    /// A forwarded profile switcher action.
    case profileSwitcher(ProfileSwitcherAction)

    /// The value for the remember me toggle was changed.
    case rememberMeChanged(Bool)

    /// Show the pre-login app settings.
    case showPreLoginSettings

    /// The toast was shown or hidden.
    case toastShown(Toast?)
}
