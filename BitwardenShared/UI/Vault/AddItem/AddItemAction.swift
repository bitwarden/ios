// MARK: - AddItemAction

/// Actions that can be handled by an `AddItemProcessor`.
enum AddItemAction: Equatable {
    /// The dismiss button was pressed.
    case dismissPressed

    /// The favorite toggle was changed.
    case favoriteChanged(Bool)

    /// The folder field was changed.
    case folderChanged(String)

    /// The generate password button was pressed.
    case generatePasswordPressed

    /// The generate username button was pressed.
    case generateUsernamePressed

    /// The master password re-prompt toggle was changed.
    case masterPasswordRePromptChanged(Bool)

    /// The name field was changed.
    case nameChanged(String)

    /// The new custom field button was pressed.
    case newCustomFieldPressed

    /// The notes field was changed.
    case notesChanged(String)

    /// The owner field was changed.
    case ownerChanged(String)

    /// The password field was changed.
    case passwordChanged(String)

    /// The setup totp button was pressed.
    case setupTotpPressed

    /// The toggle password visibility button was changed.
    case togglePasswordVisibilityChanged(Bool)

    /// The type field was changed.
    case typeChanged(String)

    /// The uri field was changed.
    case uriChanged(String)

    /// The uri settings button was pressed.
    case uriSettingsPressed

    /// The username field was changed.
    case usernameChanged(String)
}
