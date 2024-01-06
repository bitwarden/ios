import XCTest

@testable import BitwardenShared

class AlertSettingsTests: BitwardenTestCase {
    /// `appThemeOptions(action:)` constructs an `Alert` with the title, message,
    /// and options.
    func test_appThemeOptions() {
        let subject = Alert.appThemeOptions { _ in }

        XCTAssertEqual(subject.title, Localizations.theme)
        XCTAssertNil(subject.message)
        XCTAssertEqual(subject.alertActions.count, 4)
        XCTAssertEqual(subject.alertActions[0].title, Localizations.defaultSystem)
        XCTAssertEqual(subject.alertActions[1].title, Localizations.light)
        XCTAssertEqual(subject.alertActions[2].title, Localizations.dark)
        XCTAssertEqual(subject.alertActions[3].title, Localizations.cancel)
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

    /// `unlockWithPIN(completion:)` constructs an `Alert` with the correct title, message, Submit and Cancel buttons.
    func test_unlockWithPINAlert() {
        let subject = Alert.unlockWithPIN { _ in }

        XCTAssertEqual(subject.alertActions.count, 2)
        XCTAssertEqual(subject.preferredStyle, .alert)
        XCTAssertEqual(subject.title, Localizations.unlockWithPIN)
        XCTAssertEqual(subject.message, Localizations.setPINDescription)
    }
}
