/// Effects that can be processed by a `VaultUnlockProcessor`.
///
enum VaultUnlockEffect: Equatable {
    /// The vault unlock view appeared.
    case appeared

    /// The app has re-entered the foreground and is now visible to the user.
    case didEnterForeground

    /// A Profile Switcher Effect.
    case profileSwitcher(ProfileSwitcherEffect)

    /// The button to unlock the vault was pressed.
    case unlockVault

    /// The button to unlock the vault with biometrics was pressed.
    case unlockVaultWithBiometrics
}
