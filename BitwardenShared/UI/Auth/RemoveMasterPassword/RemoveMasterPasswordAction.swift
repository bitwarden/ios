// MARK: - RemoveMasterPasswordAction

/// Actions that can be processed by a `RemoveMasterPasswordProcessor`.
///
enum RemoveMasterPasswordAction: Equatable {
    /// The value for the master password was changed.
    case masterPasswordChanged(String)

    /// The reveal master password field button was pressed.
    case revealMasterPasswordFieldPressed(Bool)
}
