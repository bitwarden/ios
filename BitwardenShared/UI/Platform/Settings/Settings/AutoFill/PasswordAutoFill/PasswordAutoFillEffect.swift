// MARK: - PasswordAutoFillEffect

/// Effects handled by the `PasswordAutoFillProcessor`.
///
enum PasswordAutoFillEffect: Equatable {
    /// The password autofill view appeared on screen.
    case appeared

    /// Check the autofill status when the view enters the foreground.
    case checkAutofillOnForeground

    /// The turn on later button was tapped.
    case turnAutoFillOnLaterButtonTapped
}
