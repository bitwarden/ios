// MARK: - TwoFactorAuthAction

/// Actions that can be processed by a `TwoFactorAuthProcessor`.
enum TwoFactorAuthAction: Equatable {
    /// A two-factor authentication method was selected.
    case authMethodSelected(TwoFactorAuthMethod)

    /// The url has been opened so clear the value in the state.
    case clearURL

    /// The close button was tapped to dismiss the view.
    case dismiss

    /// The remember option was toggled.
    case rememberMeToggleChanged(Bool)

    /// The toast was shown or hidden.
    case toastShown(Toast?)

    /// The verification code text changed.
    case verificationCodeChanged(String)
}
