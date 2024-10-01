// MARK: - SettingsBadgeState

/// Data model containing the data needed for displaying badges in the settings tab.
///
struct SettingsBadgeState: Equatable {
    // MARK: Properties

    /// The user's autofill set up progress.
    let autofillSetupProgress: AccountSetupProgress?

    /// The value that should be shown in the settings tab's badge.
    let badgeValue: String?

    /// The user's vault unlock set up progress.
    let vaultUnlockSetupProgress: AccountSetupProgress?
}
