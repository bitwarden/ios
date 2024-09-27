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
}
