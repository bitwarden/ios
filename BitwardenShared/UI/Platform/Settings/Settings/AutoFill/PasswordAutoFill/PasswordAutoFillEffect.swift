// MARK: - PasswordAutoFillEffect

/// Effects handled by the `PasswordAutoFillProcessor`.
///
enum PasswordAutoFillEffect: Equatable {
    /// Check the autofill status when the view enters the foreground.
    case checkAutofillOnForeground

    /// The continue button was tapped.
    case continueTapped

    /// The turn on later button was tapped.
    case turnAutoFillOnLaterButtonTapped
}
