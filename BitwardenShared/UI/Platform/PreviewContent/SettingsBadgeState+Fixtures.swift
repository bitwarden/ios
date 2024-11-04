#if DEBUG
extension SettingsBadgeState {
    static func fixture(
        autofillSetupProgress: AccountSetupProgress? = nil,
        badgeValue: String? = nil,
        importLoginsSetupProgress: AccountSetupProgress? = nil,
        vaultUnlockSetupProgress: AccountSetupProgress? = nil
    ) -> SettingsBadgeState {
        SettingsBadgeState(
            autofillSetupProgress: autofillSetupProgress,
            badgeValue: badgeValue,
            importLoginsSetupProgress: importLoginsSetupProgress,
            vaultUnlockSetupProgress: vaultUnlockSetupProgress
        )
    }
}
#endif
