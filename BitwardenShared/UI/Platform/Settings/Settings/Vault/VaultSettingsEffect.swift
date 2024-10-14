// MARK: - VaultSettingsEffect

/// Effects that can be processed by a `VaultSettingsProcessor`.
///
enum VaultSettingsEffect: Equatable {
    /// The user tapped the dismiss button on the import logins action card.
    case dismissImportLoginsActionCard

    /// Stream the state of the badges in the settings tab.
    case streamSettingsBadge
}
