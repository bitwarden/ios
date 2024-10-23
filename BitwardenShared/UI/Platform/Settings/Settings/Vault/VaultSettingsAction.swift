// MARK: - VaultSettingsAction

/// Actions handled by the `VaultSettingsProcessor`.
///
enum VaultSettingsAction {
    /// Clears the URL.
    case clearUrl

    /// The export vault button was tapped.
    case exportVaultTapped

    /// The folders button was tapped.
    case foldersTapped

    /// The import items button was tapped.
    case importItemsTapped

    /// The user tapped the get started button on the import logins action card.
    case showImportLogins
}
