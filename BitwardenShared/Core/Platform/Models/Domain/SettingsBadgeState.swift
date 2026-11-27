// MARK: - SettingsBadgeState

/// Data model containing the data needed for displaying badges in the settings tab.
///
struct SettingsBadgeState: Equatable {
    // MARK: Properties

    /// The user's autofill setup progress.
    let autofillSetupProgress: AccountSetupProgress?

    /// The value that should be shown in the settings tab's badge.
    let badgeValue: String?

    /// The user's import logins setup progress.
    let importLoginsSetupProgress: AccountSetupProgress?

    /// The user's vault unlock setup progress.
    let vaultUnlockSetupProgress: AccountSetupProgress?

    // MARK: Computed Properties

    /// The value that should be shown in the settings tab's badge, excluding the user's autofill
    /// setup progress. This is used when the autofill off action card replaces the set up
    /// autofill badge.
    var badgeValueExcludingAutofill: String? {
        var badgeCount = 0
        if let vaultUnlockSetupProgress, vaultUnlockSetupProgress != .complete {
            badgeCount += 1
        }
        if importLoginsSetupProgress == .setUpLater {
            badgeCount += 1
        }
        return badgeCount > 0 ? String(badgeCount) : nil
    }
}
