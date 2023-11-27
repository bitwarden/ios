/// Actions that can be processed by a `VaultUnlockProcessor`.
///
enum VaultUnlockAction: Equatable {
    /// The value for the master password was changed.
    case masterPasswordChanged(String)

    /// The more button was pressed.
    case morePressed

    /// A forwarded profile switcher action.
    case profileSwitcherAction(ProfileSwitcherAction)

    /// An action to toggle the visibility of the profile switcher view.
    case requestedProfileSwitcher(visible: Bool)

    /// The reveal master password field button was pressed.
    case revealMasterPasswordFieldPressed(Bool)
}
