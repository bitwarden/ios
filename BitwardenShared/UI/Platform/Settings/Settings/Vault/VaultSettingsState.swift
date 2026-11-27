import BitwardenResources
import Foundation

// MARK: - VaultSettingsState

/// An object that defines the current state of the `VaultSettingsView`.
///
struct VaultSettingsState {
    // MARK: Properties

    /// The state of the badges in the settings tab.
    var badgeState: SettingsBadgeState?

    /// Whether the `vfo1-foundation` feature flag is enabled.
    var isVfo1FoundationFeatureFlagEnabled = false

    /// The import items URL.
    var url: URL?

    // MARK: Computed Properties

    /// The title of the folders settings list item.
    var foldersTitle: String {
        isVfo1FoundationFeatureFlagEnabled ? Localizations.myFolders : Localizations.folders
    }

    /// Whether the import logins action card should be shown.
    var shouldShowImportLoginsActionCard: Bool {
        badgeState?.importLoginsSetupProgress == .setUpLater
    }
}
