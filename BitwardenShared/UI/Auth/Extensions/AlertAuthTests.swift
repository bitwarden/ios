import XCTest

@testable import BitwardenShared

class AlertAuthTests: BitwardenTestCase {
    /// `accountOptions(_:lockAction:logoutAction:)`
    func test_accountOptions() {
        let subject = Alert.accountOptions(
            .fixture(email: "test@example.com", isUnlocked: true, webVault: "secureVault.example.com"),
            lockAction: {},
            logoutAction: {}
        )

        XCTAssertEqual(subject.title, "test@example.com\nsecureVault.example.com")
        XCTAssertNil(subject.message)
        XCTAssertEqual(subject.preferredStyle, .actionSheet)
        XCTAssertEqual(subject.alertActions.count, 3)
        XCTAssertEqual(subject.alertActions[0].title, Localizations.lock)
        XCTAssertEqual(subject.alertActions[1].title, Localizations.logOut)
        XCTAssertEqual(subject.alertActions[2].title, Localizations.cancel)
    }

    /// `breachesAlert(action:)` constructs an `Alert` with the title, message, and Yes and No buttons.
    func test_breachesAlert() {
        let subject = Alert.breachesAlert {}

        XCTAssertEqual(subject.title, Localizations.weakAndExposedMasterPassword)
        XCTAssertEqual(subject.message, Localizations.weakPasswordIdentifiedAndFoundInADataBreachAlertDescription)
        XCTAssertEqual(subject.preferredStyle, .alert)
        XCTAssertEqual(subject.alertActions.count, 2)
        XCTAssertEqual(subject.alertActions[0].title, Localizations.no)
        XCTAssertEqual(subject.alertActions[1].title, Localizations.yes)
    }

    /// `extensionKdfMemoryWarning(continueAction:)` constructs an `Alert` used to warn the user
    /// that their KDF memory setting may be too high to unlock the vault in an extension.
    func test_extensionKdfMemoryWarning() async throws {
        let subject = Alert.extensionKdfMemoryWarning {}

        XCTAssertEqual(subject.title, Localizations.warning)
        XCTAssertEqual(
            subject.message,
            Localizations.unlockingMayFailDueToInsufficientMemoryDecreaseYourKDFMemorySettingsToResolve
        )
        XCTAssertEqual(subject.preferredStyle, .alert)
        XCTAssertEqual(subject.alertActions.count, 2)
        XCTAssertEqual(subject.alertActions[0].title, Localizations.continue)
        XCTAssertEqual(subject.alertActions[1].title, Localizations.cancel)
    }

    /// `logoutConfirmation(action:)` constructs an `Alert` used to confirm that the user wants to
    /// logout of the account.
    func test_logoutConfirmation() {
        let subject = Alert.logoutConfirmation {}

        XCTAssertEqual(subject.title, Localizations.logOut)
        XCTAssertEqual(subject.message, Localizations.logoutConfirmation)
        XCTAssertEqual(subject.preferredStyle, .alert)
        XCTAssertEqual(subject.alertActions.count, 2)
        XCTAssertEqual(subject.alertActions[0].title, Localizations.yes)
        XCTAssertEqual(subject.alertActions[1].title, Localizations.cancel)
    }

    /// `dataBreachesCountAlert(count:)` constructs an alert with the correct title and alert actions.
    func test_passwordExposedAlert() {
        let subject = Alert.dataBreachesCountAlert(count: 1)

        XCTAssertEqual(subject.title, Localizations.passwordExposed(1))
        XCTAssertEqual(subject.alertActions.count, 1)
        XCTAssertEqual(subject.alertActions[0].title, Localizations.ok)
    }

    /// `dataBreachesCountAlert(count:)` constructs an alert with the correct title and alert actions.
    func test_passwordSafeAlert() {
        let subject = Alert.dataBreachesCountAlert(count: 0)

        XCTAssertEqual(subject.title, Localizations.passwordSafe)
        XCTAssertEqual(subject.alertActions.count, 1)
        XCTAssertEqual(subject.alertActions[0].title, Localizations.ok)
    }

    /// `masterPasswordInvalid()` returns an alert notifying the user that their master password is invalid.
    func test_masterPasswordInvalid() {
        let subject = Alert.masterPasswordInvalid()

        XCTAssertEqual(subject.title, Localizations.masterPasswordPolicyValidationTitle)
        XCTAssertEqual(subject.message, Localizations.masterPasswordPolicyValidationMessage)
        XCTAssertEqual(subject.alertActions.count, 1)
        XCTAssertEqual(subject.alertActions[0].title, Localizations.ok)
    }
}
