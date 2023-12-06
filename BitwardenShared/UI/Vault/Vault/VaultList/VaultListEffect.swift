// MARK: - VaultListEffect

/// Effects that can be processed by a `VaultListProcessor`.
enum VaultListEffect {
    /// The vault list appeared on screen.
    case appeared

    /// A Profile Switcher Effect.
    case profileSwitcher(ProfileSwitcherEffect)

    /// Refreshes the account profiles.
    case refreshAccountProfiles

    /// Refresh the vault list's data.
    case refreshVault
}
