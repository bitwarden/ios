import XCTest

@testable import BitwardenShared

class SettingsStateTests: BitwardenTestCase {
    /// `accountSecurityBadgeValue` returns `nil` if no badge should be shown for the account security row.
    func test_accountSecurityBadgeValue_nil() {
        var subject = SettingsState(badgeState: .fixture())
        XCTAssertNil(subject.accountSecurityBadgeValue)

        subject = SettingsState(badgeState: .fixture(autofillSetupProgress: .complete))
        XCTAssertNil(subject.accountSecurityBadgeValue)

        subject = SettingsState(badgeState: .fixture(vaultUnlockSetupProgress: .complete))
        XCTAssertNil(subject.accountSecurityBadgeValue)
    }

    /// `accountSecurityBadgeValue` returns the badge value for the account security row if the
    /// vault unlock setup isn't complete.
    func test_accountSecurityBadgeValue_value() {
        var subject = SettingsState(badgeState: .fixture(vaultUnlockSetupProgress: .incomplete))
        XCTAssertEqual(subject.accountSecurityBadgeValue, "1")

        subject = SettingsState(badgeState: .fixture(badgeValue: "2", vaultUnlockSetupProgress: .setUpLater))
        XCTAssertEqual(subject.accountSecurityBadgeValue, "1")
    }

    /// `autofillBadgeValue` returns `nil` if no badge should be shown for the autofill row.
    func test_autofillBadgeValue_nil() {
        var subject = SettingsState(badgeState: .fixture())
        XCTAssertNil(subject.autofillBadgeValue)

        subject = SettingsState(badgeState: .fixture(autofillSetupProgress: .complete))
        XCTAssertNil(subject.autofillBadgeValue)

        subject = SettingsState(badgeState: .fixture(vaultUnlockSetupProgress: .complete))
        XCTAssertNil(subject.autofillBadgeValue)
    }

    /// `autofillBadgeValue` returns the badge value for the autofill row if the autofill setup
    /// isn't complete.
    func test_autofillBadgeValue_value() {
        var subject = SettingsState(badgeState: .fixture(autofillSetupProgress: .incomplete))
        XCTAssertEqual(subject.autofillBadgeValue, "1")

        subject = SettingsState(badgeState: .fixture(autofillSetupProgress: .setUpLater, badgeValue: "2"))
        XCTAssertEqual(subject.autofillBadgeValue, "1")
    }

    /// `vaultBadgeValue` returns `nil` if no badge should be shown for the vault row.
    func test_vaultBadgeValue_nil() {
        var subject = SettingsState(badgeState: .fixture())
        XCTAssertNil(subject.vaultBadgeValue)

        subject = SettingsState(badgeState: .fixture(importLoginsSetupProgress: .incomplete))
        XCTAssertNil(subject.vaultBadgeValue)

        subject = SettingsState(badgeState: .fixture(importLoginsSetupProgress: .complete))
        XCTAssertNil(subject.vaultBadgeValue)
    }

    /// `vaultBadgeValue` returns the badge value for the vault row if the user wants to import logins later.
    func test_vaultBadgeValue_value() {
        let subject = SettingsState(badgeState: .fixture(importLoginsSetupProgress: .setUpLater))
        XCTAssertEqual(subject.vaultBadgeValue, "1")
    }
}
