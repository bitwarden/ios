import XCTest

@testable import BitwardenShared

class AlertSettingsTests: BitwardenTestCase {
    /// `confirmDeleteFolder(action:)` constructs an `Alert` with the title,
    /// message, yes, and cancel buttons to confirm deleting a folder.
    func test_confirmDeleteFolder() {
        let subject = Alert.confirmDeleteFolder {}

        XCTAssertEqual(subject.alertActions.count, 2)
        XCTAssertEqual(subject.preferredStyle, .alert)
        XCTAssertEqual(subject.title, Localizations.doYouReallyWantToDelete)
        XCTAssertNil(subject.message)
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
            Localizations.encExportKeyWarning + "\n\n" + Localizations.encExportAccountWarning
        )

        subject = Alert.confirmExportVault(encrypted: false) {}

        XCTAssertEqual(subject.alertActions.count, 2)
        XCTAssertEqual(subject.preferredStyle, .alert)
        XCTAssertEqual(subject.title, Localizations.exportVaultConfirmationTitle)
        XCTAssertEqual(subject.message, Localizations.exportVaultWarning)
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

    /// `unlockWithPINCodeAlert(action)` constructs an `Alert` with the correct title, message, Yes and No buttons.
    func test_unlockWithPINAlert() {
        let subject = Alert.unlockWithPINCodeAlert {}

        XCTAssertEqual(subject.alertActions.count, 2)
        XCTAssertEqual(subject.preferredStyle, .alert)
        XCTAssertEqual(subject.title, Localizations.unlockWithPIN)
        XCTAssertEqual(subject.message, Localizations.pinRequireMasterPasswordRestart)
    }
}
