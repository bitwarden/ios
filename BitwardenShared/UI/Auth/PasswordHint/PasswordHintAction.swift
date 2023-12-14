// MARK: - PasswordHintAction

/// Actions that can be processed by a `PasswordHintProcessor`.
enum PasswordHintAction: Equatable {
    /// The dismiss button was pressed.
    case dismissPressed

    /// The email address value was changed.
    case emailAddressChanged(String)
}
