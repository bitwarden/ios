// MARK: - UpdateMasterPasswordAction

/// Actions that can be processed by a `UpdateMasterPasswordView`.
enum UpdateMasterPasswordAction: Equatable {
    /// The value for the current master password was changed.
    case currentMasterPasswordChanged(String)

    /// The value for the new master password was changed.
    case masterPasswordChanged(String)

    /// The value for the new master password hint was changed.
    case masterPasswordHintChanged(String)

    /// The value for the new master password retype was changed.
    case masterPasswordRetypeChanged(String)

    /// The reveal current master password field button was pressed.
    case revealCurrentMasterPasswordFieldPressed(Bool)

    /// The reveal master password field button was pressed.
    case revealMasterPasswordFieldPressed(Bool)

    /// The reveal master password retype field button was pressed.
    case revealMasterPasswordRetypeFieldPressed(Bool)
}
