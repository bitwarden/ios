/// An object that defines the current state of a `SettingsView`.
///
struct SettingsState: Equatable {
    // MARK: Properties

    /// The state of the badges in the settings tab.
    var badgeState: SettingsBadgeState?

    // MARK: Computed Properties

    /// The badge value for the account security row.
    var accountSecurityBadgeValue: String? {
        let isComplete = badgeState?.vaultUnlockSetupProgress?.isComplete ?? true
        return isComplete ? nil : "1"
    }

    /// The badge value for the autofill row.
    var autofillBadgeValue: String? {
        let isComplete = badgeState?.autofillSetupProgress?.isComplete ?? true
        return isComplete ? nil : "1"
    }

    /// The badge value for the vault row.
    var vaultBadgeValue: String? {
        // Since the action card displays on the vault when the progress is incomplete, only show a
        // badge value if the user wants to set it up later.
        badgeState?.importLoginsSetupProgress == .setUpLater ? "1" : nil
    }
}
