// MARK: - PasswordAutoFillEffect

/// Effects handled by the `PasswordAutoFillProcessor`.
///
enum PasswordAutoFillEffect: Equatable {
    /// The password autofill view appeared on screen.
    case appeared

    /// The turn on later button was tapped.
    case turnAutoFillOnLaterButtonTapped
}
