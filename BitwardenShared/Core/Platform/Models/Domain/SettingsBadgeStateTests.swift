import Testing

@testable import BitwardenShared

// MARK: - SettingsBadgeStateTests

struct SettingsBadgeStateTests {
    // MARK: Tests

    /// `badgeValueExcludingAutofill` counts the vault unlock and import logins setup progress,
    /// ignoring the autofill setup progress.
    @Test(arguments: [
        (AccountSetupProgress?.none, AccountSetupProgress?.none, AccountSetupProgress?.none, String?.none),
        (.setUpLater, nil, nil, nil),
        (.incomplete, .complete, .complete, nil),
        (.setUpLater, .setUpLater, nil, "1"),
        (nil, .complete, .setUpLater, "1"),
        (.setUpLater, .setUpLater, .setUpLater, "2"),
        (nil, nil, .incomplete, nil),
    ])
    func badgeValueExcludingAutofill(
        autofill: AccountSetupProgress?,
        vaultUnlock: AccountSetupProgress?,
        importLogins: AccountSetupProgress?,
        expected: String?,
    ) {
        let subject = SettingsBadgeState.fixture(
            autofillSetupProgress: autofill,
            importLoginsSetupProgress: importLogins,
            vaultUnlockSetupProgress: vaultUnlock,
        )
        #expect(subject.badgeValueExcludingAutofill == expected)
    }
}
