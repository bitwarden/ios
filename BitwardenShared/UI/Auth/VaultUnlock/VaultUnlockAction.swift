/// Actions that can be processed by a `VaultUnlockProcessor`.
///
enum VaultUnlockAction: Equatable {
    /// The cancel button was pressed.
    case cancelPressed

    /// The value for the master password was changed.
    case masterPasswordChanged(String)

    /// The more button was pressed.
    case morePressed

    /// A forwarded profile switcher action.
    case profileSwitcher(ProfileSwitcherAction)

    /// The value for the PIN was changed.
    case pinChanged(String)

    /// The toast was shown or hidden.
    case toastShown(Toast?)

    /// The reveal master password field button was pressed.
    case revealMasterPasswordFieldPressed(Bool)

    /// The reveal PIN field button was pressed.
    case revealPinFieldPressed(Bool)
}
