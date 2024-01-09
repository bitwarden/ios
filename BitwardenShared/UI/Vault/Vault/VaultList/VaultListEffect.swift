// MARK: - VaultListEffect

/// Effects that can be processed by a `VaultListProcessor`.
enum VaultListEffect: Equatable {
    /// The vault list appeared on screen.
    case appeared

    /// The more button was pressed on an item in the vault.
    case morePressed(item: VaultListItem)

    /// A Profile Switcher Effect.
    case profileSwitcher(ProfileSwitcherEffect)

    /// Refreshes the account profiles.
    case refreshAccountProfiles

    /// Refresh the vault list's data.
    case refreshVault

    /// Searches based on the keyword.
    case search(String)

    /// Stream the list of organizations for the user.
    case streamOrganizations

    /// Stream the vault list for the user.
    case streamVaultList
}
