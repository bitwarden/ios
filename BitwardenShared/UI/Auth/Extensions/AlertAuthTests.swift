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

    /// `passwordStrengthAlert(alert:action:)` constructs an `Alert` with the title, message, and Yes and No buttons.
    func test_passwordStrengthAlert() {
        var subject = Alert.passwordStrengthAlert(.weak) {}

        XCTAssertEqual(subject.title, Localizations.weakMasterPassword)
        XCTAssertEqual(subject.message, Localizations.weakPasswordIdentifiedUseAStrongPasswordToProtectYourAccount)
        XCTAssertEqual(subject.preferredStyle, .alert)
        XCTAssertEqual(subject.alertActions.count, 2)
        XCTAssertEqual(subject.alertActions[0].title, Localizations.no)
        XCTAssertEqual(subject.alertActions[1].title, Localizations.yes)

        subject = Alert.passwordStrengthAlert(.exposedWeak) {}

        XCTAssertEqual(subject.title, Localizations.weakAndExposedMasterPassword)
        XCTAssertEqual(subject.message, Localizations.weakPasswordIdentifiedAndFoundInADataBreachAlertDescription)
        XCTAssertEqual(subject.preferredStyle, .alert)
        XCTAssertEqual(subject.alertActions.count, 2)
        XCTAssertEqual(subject.alertActions[0].title, Localizations.no)
        XCTAssertEqual(subject.alertActions[1].title, Localizations.yes)

        subject = Alert.passwordStrengthAlert(.exposedStrong) {}

        XCTAssertEqual(subject.title, Localizations.exposedMasterPassword)
        XCTAssertEqual(subject.message, Localizations.passwordFoundInADataBreachAlertDescription)
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

    /// `enterPINCode(completion:)` constructs an `Alert`
    /// with the correct title, message, Submit and Cancel buttons when setting it up.
    func test_enterPINCodeAlert_when_setting_it_up() {
        let subject = Alert.enterPINCode { _ in }

        XCTAssertEqual(subject.alertActions.count, 2)
        XCTAssertEqual(subject.preferredStyle, .alert)
        XCTAssertEqual(subject.title, Localizations.enterPIN)
        XCTAssertEqual(subject.message, Localizations.setPINDescription)
    }

    /// `enterPINCode(completion:settingUp:)` constructs an `Alert`
    /// with the correct title, message, Submit and Cancel buttons when verifying it.
    func test_enterPINCodeAlert_when_verifying() {
        let subject = Alert.enterPINCode(settingUp: false, completion: { _ in })

        XCTAssertEqual(subject.alertActions.count, 2)
        XCTAssertEqual(subject.preferredStyle, .alert)
        XCTAssertEqual(subject.title, Localizations.enterPIN)
        XCTAssertEqual(subject.message, Localizations.verifyPIN)
    }

    /// `enterPINCode(completion:settingUp:)` constructs an `Alert`
    /// with completion closure expecting pin
    func test_enterPINCodeAlert_completion_with_pin() async throws {
        let expectedPin = "myPin"
        let expectation = expectation(description: #function)

        let subject = Alert.enterPINCode(settingUp: false) { pin in
            expectation.fulfill()

            XCTAssertEqual(expectedPin, pin)
        }

        var textField = try XCTUnwrap(subject.alertTextFields.first)
        textField = AlertTextField(id: "pin", text: expectedPin)

        try await subject.tapAction(title: Localizations.submit, alertTextFields: [textField])

        await fulfillment(of: [expectation], timeout: 3)
    }

    /// `enterPINCode(completion:settingUp:)` constructs an `Alert`
    /// with cancel closure and it gets fired when tapping on cancel
    func test_enterPINCodeAlert_cancel() async throws {
        let expectation = expectation(description: #function)

        let subject = Alert.enterPINCode(
            onCancelled: { () in expectation.fulfill() },
            settingUp: false,
            completion: { _ in }
        )

        try await subject.tapAction(title: Localizations.cancel)

        await fulfillment(of: [expectation], timeout: 3)
    }

    /// `setUpUnlockMethodLater(action:)` builds an `Alert` confirming the user wants to set up
    /// their unlock methods later.
    func test_setUpUnlockMethodLater() async throws {
        var actionCalled = false
        let subject = Alert.setUpUnlockMethodLater {
            actionCalled = true
        }

        XCTAssertEqual(subject.title, Localizations.setUpLaterQuestion)
        XCTAssertEqual(subject.message, Localizations.youCanFinishSetupUnlockAnytimeDescriptionLong)
        XCTAssertEqual(subject.preferredStyle, .alert)
        XCTAssertEqual(subject.alertActions.count, 2)
        XCTAssertEqual(subject.alertActions[0].title, Localizations.cancel)
        XCTAssertEqual(subject.alertActions[1].title, Localizations.confirm)

        try await subject.tapAction(title: Localizations.cancel)
        XCTAssertFalse(actionCalled)

        try await subject.tapAction(title: Localizations.confirm)
        XCTAssertTrue(actionCalled)
    }

    /// `switchToExistingAccount(action:)` builds an `Alert` for switching to an existing account.
    func test_switchToExistingAccount() async throws {
        var actionCalled = false
        let subject = Alert.switchToExistingAccount {
            actionCalled = true
        }

        XCTAssertEqual(subject.title, Localizations.accountAlreadyAdded)
        XCTAssertEqual(subject.message, Localizations.switchToAlreadyAddedAccountConfirmation)
        XCTAssertEqual(subject.preferredStyle, .alert)
        XCTAssertEqual(subject.alertActions.count, 2)
        XCTAssertEqual(subject.alertActions[0].title, Localizations.cancel)
        XCTAssertEqual(subject.alertActions[1].title, Localizations.yes)

        try await subject.tapAction(title: Localizations.cancel)
        XCTAssertFalse(actionCalled)

        try await subject.tapAction(title: Localizations.yes)
        XCTAssertTrue(actionCalled)
    }
}
