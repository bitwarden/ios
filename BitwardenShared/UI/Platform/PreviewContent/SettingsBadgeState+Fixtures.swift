#if DEBUG
extension SettingsBadgeState {
    static func fixture(
        autofillSetupProgress: AccountSetupProgress? = nil,
        badgeValue: String? = nil,
        vaultUnlockSetupProgress: AccountSetupProgress? = nil
    ) -> SettingsBadgeState {
        SettingsBadgeState(
            autofillSetupProgress: autofillSetupProgress,
            badgeValue: badgeValue,
            vaultUnlockSetupProgress: vaultUnlockSetupProgress
        )
    }
}
#endif
