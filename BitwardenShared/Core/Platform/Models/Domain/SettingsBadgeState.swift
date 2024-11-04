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
}
