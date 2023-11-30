/// Actions that can be processed by a `VaultUnlockProcessor`.
///
enum VaultUnlockAction: Equatable {
    /// The value for the master password was changed.
    case masterPasswordChanged(String)

    /// The more button was pressed.
    case morePressed

    /// A forwarded profile switcher action.
    case profileSwitcherAction(ProfileSwitcherAction)

    /// The reveal master password field button was pressed.
    case revealMasterPasswordFieldPressed(Bool)
}
