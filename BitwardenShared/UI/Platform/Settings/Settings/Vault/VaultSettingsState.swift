import Foundation

// MARK: - VaultSettingsState

/// An object that defines the current state of the `VaultSettingsView`.
///
struct VaultSettingsState {
    // MARK: Properties

    /// The state of the badges in the settings tab.
    var badgeState: SettingsBadgeState?

    /// The import items URL.
    var url: URL?

    // MARK: Computed Properties

    /// Whether the import logins action card should be shown.
    var shouldShowImportLoginsActionCard: Bool {
        badgeState?.importLoginsSetupProgress == .setUpLater
    }
}
