import XCTest

@testable import BitwardenShared

class AlertSettingsTests: BitwardenTestCase {
    /// `appStoreAlert(action:)` constructs an `Alert` with the title,
    /// message, cancel, and continue buttons to confirm navigating to the app store.
    func test_appStoreAlert() {
        let subject = Alert.appStoreAlert {}

        XCTAssertEqual(subject.alertActions.count, 2)
        XCTAssertEqual(subject.preferredStyle, .alert)
        XCTAssertEqual(subject.title, Localizations.continueToAppStore)
        XCTAssertEqual(subject.message, Localizations.rateAppDescriptionLong)
        XCTAssertEqual(subject.alertActions[0].title, Localizations.cancel)
        XCTAssertEqual(subject.alertActions[0].style, .cancel)
        XCTAssertEqual(subject.alertActions[1].title, Localizations.continue)
        XCTAssertEqual(subject.alertActions[1].style, .default)
    }

    /// `confirmApproveLoginRequests(action:)` constructs an `Alert` with the title,
    /// message, yes, and cancel buttons to confirm approving login requests
    func test_confirmApproveLoginRequests() {
        let subject = Alert.confirmApproveLoginRequests {}

        XCTAssertEqual(subject.title, Localizations.approveLoginRequests)
        XCTAssertEqual(subject.message, Localizations.useThisDeviceToApproveLoginRequestsMadeFromOtherDevices)
        XCTAssertEqual(subject.preferredStyle, .alert)
        XCTAssertEqual(subject.alertActions.count, 2)
        XCTAssertEqual(subject.alertActions.first?.title, Localizations.no)
        XCTAssertEqual(subject.alertActions.first?.style, .cancel)
        XCTAssertEqual(subject.alertActions.last?.title, Localizations.yes)
        XCTAssertEqual(subject.alertActions.last?.style, .default)
    }

    /// `confirmDeleteFolder(action:)` constructs an `Alert` with the title,
    /// message, yes, and cancel buttons to confirm deleting a folder.
    func test_confirmDeleteFolder() {
        let subject = Alert.confirmDeleteFolder {}

        XCTAssertEqual(subject.alertActions.count, 2)
        XCTAssertEqual(subject.preferredStyle, .alert)
        XCTAssertEqual(subject.title, Localizations.doYouReallyWantToDelete)
        XCTAssertNil(subject.message)
    }

    /// `confirmDenyingAllRequests(action:)` constructs an `Alert` with the title,
    /// message, yes, and cancel buttons to confirm denying all login requests
    func test_confirmDenyingAllRequests() {
        let subject = Alert.confirmDenyingAllRequests {}

        XCTAssertEqual(subject.title, Localizations.areYouSureYouWantToDeclineAllPendingLogInRequests)
        XCTAssertNil(subject.message)
        XCTAssertEqual(subject.preferredStyle, .alert)
        XCTAssertEqual(subject.alertActions.count, 2)
        XCTAssertEqual(subject.alertActions.first?.title, Localizations.no)
        XCTAssertEqual(subject.alertActions.first?.style, .cancel)
        XCTAssertEqual(subject.alertActions.last?.title, Localizations.yes)
        XCTAssertEqual(subject.alertActions.last?.style, .default)
    }

    /// `confirmExportVault(encrypted:action:)` constructs an `Alert` with the title, message, and Yes and Export vault
    /// buttons.
    func test_confirmExportVault() {
        var subject = Alert.confirmExportVault(encrypted: true) {}

        XCTAssertEqual(subject.alertActions.count, 2)
        XCTAssertEqual(subject.preferredStyle, .alert)
        XCTAssertEqual(subject.title, Localizations.exportVaultConfirmationTitle)
        XCTAssertEqual(
            subject.message,
            Localizations.encExportKeyWarning + .newLine + Localizations.encExportAccountWarning
        )

        subject = Alert.confirmExportVault(encrypted: false) {}

        XCTAssertEqual(subject.alertActions.count, 2)
        XCTAssertEqual(subject.preferredStyle, .alert)
        XCTAssertEqual(subject.title, Localizations.exportVaultConfirmationTitle)
        XCTAssertEqual(subject.message, Localizations.exportVaultWarning)
    }

    /// `languageChanged(to:)` constructs an `Alert` with the title and ok buttons.
    func test_languageChanged() {
        let subject = Alert.languageChanged(to: "Thai") {}

        XCTAssertEqual(subject.title, Localizations.languageChangeXDescription("Thai"))
        XCTAssertNil(subject.message)
        XCTAssertEqual(subject.preferredStyle, .alert)
        XCTAssertEqual(subject.alertActions.count, 1)
        XCTAssertEqual(subject.alertActions.first?.title, Localizations.ok)
        XCTAssertEqual(subject.alertActions.first?.style, .default)
    }

    /// `logoutOnTimeoutAlert(action:)` constructs an `Alert` with the title, message, and Yes and Cancel buttons.
    func test_logoutOnTimeoutAlert() {
        let subject = Alert.logoutOnTimeoutAlert {}

        XCTAssertEqual(subject.alertActions.count, 2)
        XCTAssertEqual(subject.preferredStyle, .alert)
        XCTAssertEqual(subject.title, Localizations.warning)
        XCTAssertEqual(subject.message, Localizations.vaultTimeoutLogOutConfirmation)
    }

    /// `enterPINCode(completion:)` constructs an `Alert` with the correct title, message, Submit and Cancel buttons.
    func test_enterPINCodeAlert() {
        let subject = Alert.enterPINCode { _ in }

        XCTAssertEqual(subject.alertActions.count, 2)
        XCTAssertEqual(subject.preferredStyle, .alert)
        XCTAssertEqual(subject.title, Localizations.enterPIN)
        XCTAssertEqual(subject.message, Localizations.setPINDescription)
    }

    /// `timeoutExceedsPolicyLengthAlert()` constructs an `Alert` with the correct title, message, and Ok button.
    func test_timeoutExceedsPolicyLengthAlert() {
        let subject = Alert.timeoutExceedsPolicyLengthAlert()

        XCTAssertEqual(subject.title, Localizations.warning)
        XCTAssertEqual(subject.message, Localizations.vaultTimeoutToLarge)
        XCTAssertEqual(subject.alertActions.first?.title, Localizations.ok)
        XCTAssertEqual(subject.alertActions.count, 1)
        XCTAssertEqual(subject.alertActions.first?.style, .default)
    }

    /// `unlockWithPINCodeAlert(action)` constructs an `Alert` with the correct title, message, Yes and No buttons.
    func test_unlockWithPINAlert() {
        let subject = Alert.unlockWithPINCodeAlert { _ in }

        XCTAssertEqual(subject.alertActions.count, 2)
        XCTAssertEqual(subject.preferredStyle, .alert)
        XCTAssertEqual(subject.title, Localizations.unlockWithPIN)
        XCTAssertEqual(subject.message, Localizations.pinRequireMasterPasswordRestart)
    }
}
