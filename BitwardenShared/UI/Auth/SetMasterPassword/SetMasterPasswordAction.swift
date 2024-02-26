// MARK: - SetMasterPasswordAction

/// Actions that can be processed by a `SetMasterPasswordProcessor`.
///
enum SetMasterPasswordAction: Equatable {
    /// The value for the new master password was changed.
    case masterPasswordChanged(String)

    /// The value for the new master password hint was changed.
    case masterPasswordHintChanged(String)

    /// The value for the new master password retype was changed.
    case masterPasswordRetypeChanged(String)

    /// The reveal master password field button was pressed.
    case revealMasterPasswordFieldPressed(Bool)
}
