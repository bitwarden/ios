import BitwardenResources
import XCTest

@testable import AuthenticatorShared

class AlertSettingsTests: BitwardenTestCase {
    /// `backupInformation(action:)` constructs an `Alert`
    /// with the correct title, message, and buttons.
    func test_backupInformationAlert() {
        let subject = Alert.backupInformation {}

        XCTAssertEqual(subject.preferredStyle, .alert)
        XCTAssertEqual(subject.title, Localizations.bitwardenAuthenticatorDataIsBackedUpAndCanBeRestored)
        XCTAssertNil(subject.message)
        XCTAssertEqual(subject.alertActions.count, 2)
        XCTAssertEqual(subject.alertActions.first?.title, Localizations.learnMore)
        XCTAssertEqual(subject.alertActions.first?.style, .default)
        XCTAssertEqual(subject.alertActions.last?.title, Localizations.ok)
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

    /// `confirmExportItems(action:)` constructs an `Alert`
    ///  with the title, message, and Yes and Export items buttons.
    func test_confirmExportVault() {
        let subject = Alert.confirmExportItems {}

        XCTAssertEqual(subject.alertActions.count, 2)
        XCTAssertEqual(subject.preferredStyle, .alert)
        XCTAssertEqual(subject.title, Localizations.exportItemsConfirmationTitle)
        XCTAssertEqual(subject.message, Localizations.exportItemsWarning)
    }

    /// `languageChanged(to:)` constructs an `Alert` with the title and ok buttons.
    @MainActor
    func test_languageChanged() {
        let subject = Alert.languageChanged(to: "Thai") {}

        XCTAssertEqual(subject.title, Localizations.languageChangeXDescription("Thai"))
        XCTAssertNil(subject.message)
        XCTAssertEqual(subject.preferredStyle, .alert)
        XCTAssertEqual(subject.alertActions.count, 1)
        XCTAssertEqual(subject.alertActions.first?.title, Localizations.ok)
        XCTAssertEqual(subject.alertActions.first?.style, .default)
    }

    /// `privacyPolicyAlert(action:)` constructs an `Alert`
    /// with the correct title, message, and Cancel and Continue buttons.
    func test_privacyPolicyAlert() {
        let subject = Alert.privacyPolicyAlert {}

        XCTAssertEqual(subject.preferredStyle, .alert)
        XCTAssertEqual(subject.title, Localizations.continueToPrivacyPolicy)
        XCTAssertEqual(subject.message, Localizations.privacyPolicyDescriptionLong)
        XCTAssertEqual(subject.alertActions.count, 2)
        XCTAssertEqual(subject.alertActions.first?.title, Localizations.cancel)
        XCTAssertEqual(subject.alertActions.first?.style, .cancel)
        XCTAssertEqual(subject.alertActions.last?.title, Localizations.continue)
        XCTAssertEqual(subject.alertActions.last?.style, .default)
    }
}
