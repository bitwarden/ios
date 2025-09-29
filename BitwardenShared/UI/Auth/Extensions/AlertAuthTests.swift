import BitwardenKit
import BitwardenResources
import XCTest

@testable import BitwardenShared

class AlertAuthTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    /// `accountOptions(_:lockAction:logoutAction:removeAccountAction:)`
    func test_accountOptions() async throws {
        var actions = [String]()
        let subject = Alert.accountOptions(
            .fixture(email: "test@example.com", isUnlocked: true, webVault: "secureVault.example.com"),
            lockAction: { actions.append(Localizations.lock) },
            logoutAction: { actions.append(Localizations.logOut) },
            removeAccountAction: { actions.append(Localizations.removeAccount) }
        )

        XCTAssertEqual(subject.title, "test@example.com\nsecureVault.example.com")
        XCTAssertNil(subject.message)
        XCTAssertEqual(subject.preferredStyle, .actionSheet)
        XCTAssertEqual(subject.alertActions.count, 3)
        XCTAssertEqual(subject.alertActions[0].title, Localizations.lock)
        XCTAssertEqual(subject.alertActions[1].title, Localizations.logOut)
        XCTAssertEqual(subject.alertActions[2].title, Localizations.cancel)

        try await subject.tapAction(title: Localizations.lock)
        XCTAssertEqual(actions, [Localizations.lock])
        actions.removeAll()

        try await subject.tapAction(title: Localizations.logOut)
        XCTAssertEqual(actions, [Localizations.logOut])
        actions.removeAll()

        try await subject.tapAction(title: Localizations.cancel)
        XCTAssertTrue(actions.isEmpty)
    }

    /// `accountOptions(_:lockAction:logoutAction:removeAccountAction:)` shows the account options
    /// for a logged out account.
    func test_accountOptions_loggedOut() async throws {
        var actions = [String]()
        let subject = Alert.accountOptions(
            .fixture(email: "test@example.com", isLoggedOut: true, webVault: "secureVault.example.com"),
            lockAction: { actions.append(Localizations.lock) },
            logoutAction: { actions.append(Localizations.logOut) },
            removeAccountAction: { actions.append(Localizations.removeAccount) }
        )

        XCTAssertEqual(subject.title, "test@example.com\nsecureVault.example.com")
        XCTAssertNil(subject.message)
        XCTAssertEqual(subject.preferredStyle, .actionSheet)
        XCTAssertEqual(subject.alertActions.count, 2)
        XCTAssertEqual(subject.alertActions[0].title, Localizations.removeAccount)
        XCTAssertEqual(subject.alertActions[1].title, Localizations.cancel)

        try await subject.tapAction(title: Localizations.removeAccount)
        XCTAssertEqual(actions, [Localizations.removeAccount])
        actions.removeAll()

        try await subject.tapAction(title: Localizations.cancel)
        XCTAssertTrue(actions.isEmpty)
    }

    /// `accountOptions(_:lockAction:logoutAction:)` shows the account options for can not be locked account.
    func test_accountOptions_cantBeLocked() async throws {
        let subject = Alert.accountOptions(
            .fixture(
                canBeLocked: false,
                email: "test@example.com",
                isLoggedOut: false,
                isUnlocked: true,
                webVault: "secureVault.example.com"
            ),
            lockAction: {},
            logoutAction: {},
            removeAccountAction: {}
        )

        XCTAssertEqual(subject.title, "test@example.com\nsecureVault.example.com")
        XCTAssertNil(subject.message)
        XCTAssertEqual(subject.preferredStyle, .actionSheet)
        XCTAssertEqual(subject.alertActions.count, 2)
        XCTAssertEqual(subject.alertActions[0].title, Localizations.logOut)
        XCTAssertEqual(subject.alertActions[1].title, Localizations.cancel)
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

    /// `leaveOrganizationConfirmation(orgName:action:)` constructs an `Alert` used to confirm that the user wants to
    /// leave the organization.
    func test_leaveOrganizationConfirmation() {
        let orgName = "orgName"
        let subject = Alert.leaveOrganizationConfirmation(orgName: orgName) {}

        XCTAssertEqual(subject.title, Localizations.leaveOrganization)
        XCTAssertEqual(subject.message, Localizations.leaveOrganizationName(orgName))
        XCTAssertEqual(subject.preferredStyle, .alert)
        XCTAssertEqual(subject.alertActions.count, 2)
        XCTAssertEqual(subject.alertActions[0].title, Localizations.yes)
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

    /// `keyConnectorConfirmation()` returns an alert asking the user to confirm the key connector domain.
    func test_keyConnectorConfirmation() {
        let url = URL(string: "http://example.com")!
        let subject = Alert.keyConnectorConfirmation(keyConnectorUrl: url) {}

        XCTAssertEqual(subject.title, Localizations.confirmKeyConnectorDomain)
        XCTAssertEqual(subject.message, Localizations.keyConnectorConfirmDomainWithAdmin(url))
        XCTAssertEqual(subject.alertActions.count, 2)
        XCTAssertEqual(subject.alertActions[0].title, Localizations.yes)
        XCTAssertEqual(subject.alertActions[1].title, Localizations.cancel)
    }

    /// `masterPasswordInvalid()` returns an alert notifying the user that their master password is invalid.
    func test_masterPasswordInvalid() {
        let subject = Alert.masterPasswordInvalid()

        XCTAssertEqual(subject.title, Localizations.masterPasswordPolicyValidationTitle)
        XCTAssertEqual(subject.message, Localizations.masterPasswordPolicyValidationMessage)
        XCTAssertEqual(subject.alertActions.count, 1)
        XCTAssertEqual(subject.alertActions[0].title, Localizations.ok)
    }

    /// `encryptionKeyMigrationRequiredAlert()` returns an alert notifying the user that they need to visit web vault.
    func test_encryptionKeyMigrationRequiredAlert() {
        let subject = Alert.encryptionKeyMigrationRequiredAlert(environmentUrl: "bitwarden.com")

        XCTAssertEqual(subject.title, Localizations.anErrorHasOccurred)
        XCTAssertEqual(
            subject.message,
            Localizations.thisAccountWillSoonBeDeletedLogInAtXToContinueUsingBitwarden("bitwarden.com"),
        )
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
        XCTAssertEqual(subject.message,
                       Localizations.yourPINMustBeAtLeastXCharactersDescriptionLong(Constants.minimumPinLength))
    }

    /// `enterPINCode(completion:settingUp:)` disables the "Submit" button when the text field is empty,
    /// and enables it dynamically when the user enters a pin with the minimum length.
    @MainActor
    func test_enterPINCode_enablesSubmitButtonWhenMinimumLengthPinIsEntered() async throws {
        let alert = Alert.enterPINCode(settingUp: true) { _ in }
        let controller = alert.createAlertController()

        let pinWithMinimumLength = String(repeating: "1", count: Constants.minimumPinLength)

        let uiTextField = try XCTUnwrap(controller.textFields?.first)
        let submitAction = try XCTUnwrap(
            controller.actions.first(where: { $0.title == Localizations.submit })
        )

        uiTextField.text = String(repeating: "1", count: Constants.minimumPinLength - 1)
        alert.alertTextFields.first?.textChanged(in: uiTextField)

        XCTAssertFalse(submitAction.isEnabled)

        uiTextField.text = pinWithMinimumLength
        alert.alertTextFields.first?.textChanged(in: uiTextField)

        XCTAssertTrue(submitAction.isEnabled)
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

    /// `removeAccountConfirmation(action:)` constructs an `Alert` used to confirm that the user
    /// wants to remove the account.
    func test_removeAccountConfirmation() async throws {
        var actionCalled = false
        let subject = Alert.removeAccountConfirmation(.fixture(email: "user@bitwarden.com")) {
            actionCalled = true
        }

        XCTAssertEqual(subject.title, Localizations.removeAccount)
        XCTAssertEqual(
            subject.message,
            Localizations.removeAccountConfirmation + "\n\n" + "user@bitwarden.com\nvault.bitwarden.com"
        )
        XCTAssertEqual(subject.preferredStyle, .alert)
        XCTAssertEqual(subject.alertActions.count, 2)
        XCTAssertEqual(subject.alertActions[0].title, Localizations.yes)
        XCTAssertEqual(subject.alertActions[1].title, Localizations.cancel)

        try await subject.tapAction(title: Localizations.cancel)
        XCTAssertFalse(actionCalled)

        try await subject.tapAction(title: Localizations.yes)
        XCTAssertTrue(actionCalled)
    }

    /// `setUpAutoFillLater(action:)` builds an `Alert` for setting up autofill later.
    func test_setUpAutoFillLater() async throws {
        var actionCalled = false
        let subject = Alert.setUpAutoFillLater {
            actionCalled = true
        }

        XCTAssertEqual(subject.title, Localizations.turnOnAutoFillLaterQuestion)
        XCTAssertEqual(subject.message, Localizations.youCanReturnToCompleteThisStepAnytimeInSettings)
        XCTAssertEqual(subject.preferredStyle, .alert)
        XCTAssertEqual(subject.alertActions.count, 2)
        XCTAssertEqual(subject.alertActions[0].title, Localizations.cancel)
        XCTAssertEqual(subject.alertActions[1].title, Localizations.confirm)

        try await subject.tapAction(title: Localizations.cancel)
        XCTAssertFalse(actionCalled)

        try await subject.tapAction(title: Localizations.confirm)
        XCTAssertTrue(actionCalled)
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
