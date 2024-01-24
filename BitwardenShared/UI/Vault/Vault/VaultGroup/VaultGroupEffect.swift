// MARK: - VaultGroupEffect

/// Effects that can be handled by a `VaultGroupProcessor`.
enum VaultGroupEffect: Equatable {
    /// The vault group view appeared on screen.
    case appeared

    /// The refresh control was triggered.
    case refresh

    /// Searches based on the keyword.
    case search(String)

    /// Stream the list of organizations for the user.
    case streamOrganizations

    /// Stream the show web icons setting.
    case streamShowWebIcons

    /// Stream the vault list for the user.
    case streamVaultList
}
