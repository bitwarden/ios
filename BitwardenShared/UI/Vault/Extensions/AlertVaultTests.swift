import XCTest

@testable import BitwardenShared

class AlertVaultTests: BitwardenTestCase {
    /// `confirmCloneExcludesFido2Credential(action:)` constructs an alert to confirm whether to
    /// clone the item without the FIDO2 credential.
    func test_confirmCloneExcludesFido2Credential() async throws {
        var actionCalled: Bool?
        let subject = Alert.confirmCloneExcludesFido2Credential { actionCalled = true }

        XCTAssertEqual(subject.title, Localizations.passkeyWillNotBeCopied)
        XCTAssertEqual(
            subject.message,
            Localizations.thePasskeyWillNotBeCopiedToTheClonedItemDoYouWantToContinueCloningThisItem
        )
        XCTAssertEqual(subject.alertActions.count, 2)

        XCTAssertEqual(subject.alertActions[0].title, Localizations.yes)
        XCTAssertEqual(subject.alertActions[0].style, .default)
        try await subject.tapAction(title: Localizations.yes)
        XCTAssertEqual(actionCalled, true)
        actionCalled = nil

        XCTAssertEqual(subject.alertActions[1].title, Localizations.no)
        XCTAssertEqual(subject.alertActions[1].style, .cancel)
        try await subject.tapAction(title: Localizations.no)
        XCTAssertNil(actionCalled)
    }

    /// `confirmDeleteAttachment(action:)` shows an `Alert` that asks the user to confirm deleting
    /// an attachment.
    func test_confirmDeleteAttachment() {
        let subject = Alert.confirmDeleteAttachment {}

        XCTAssertEqual(subject.title, Localizations.doYouReallyWantToDelete)
        XCTAssertNil(subject.message)
        XCTAssertEqual(subject.alertActions.count, 2)
        XCTAssertEqual(subject.alertActions.first?.title, Localizations.yes)
        XCTAssertEqual(subject.alertActions.first?.style, .default)
        XCTAssertEqual(subject.alertActions.last?.title, Localizations.no)
        XCTAssertEqual(subject.alertActions.last?.style, .cancel)
    }

    /// `attachmentOptions(handler:)` constructs an `Alert` that presents the user with options
    /// to select an attachment type.
    func test_fileSelectionOptions() {
        let subject = Alert.fileSelectionOptions { _ in }

        XCTAssertNil(subject.title)
        XCTAssertNil(subject.message)
        XCTAssertEqual(subject.preferredStyle, .actionSheet)
        XCTAssertEqual(subject.alertActions.count, 4)
        XCTAssertEqual(subject.alertActions[0].title, Localizations.photos)
        XCTAssertEqual(subject.alertActions[0].style, .default)
        XCTAssertEqual(subject.alertActions[1].title, Localizations.camera)
        XCTAssertEqual(subject.alertActions[1].style, .default)
        XCTAssertEqual(subject.alertActions[2].title, Localizations.browse)
        XCTAssertEqual(subject.alertActions[2].style, .default)
        XCTAssertEqual(subject.alertActions[3].title, Localizations.cancel)
        XCTAssertEqual(subject.alertActions[3].style, .cancel)
    }

    /// `static importLoginsLater(action:)` constructs an `Alert` that confirms that the user
    /// wants to import logins later in settings.
    func test_importLoginsLater() async throws {
        var actionCalled = false
        let subject = Alert.importLoginsLater { actionCalled = true }

        XCTAssertEqual(subject.title, Localizations.importLoginsLaterQuestion)
        XCTAssertEqual(subject.message, Localizations.youCanReturnToCompleteThisStepAnytimeInVaultUnderSettings)
        XCTAssertEqual(subject.alertActions[0].title, Localizations.cancel)
        XCTAssertEqual(subject.alertActions[0].style, .cancel)
        XCTAssertEqual(subject.alertActions[1].title, Localizations.confirm)
        XCTAssertEqual(subject.alertActions[1].style, .default)

        try await subject.tapCancel()
        XCTAssertFalse(actionCalled)

        try await subject.tapAction(title: Localizations.confirm)
        XCTAssertTrue(actionCalled)
    }

    /// `passwordAutofillInformation()` constructs an `Alert` that informs the user about password
    /// autofill.
    func test_passwordAutofillInformation() {
        let subject = Alert.passwordAutofillInformation()

        XCTAssertEqual(subject.title, Localizations.passwordAutofill)
        XCTAssertEqual(subject.message, Localizations.bitwardenAutofillAlert2)
        XCTAssertEqual(subject.alertActions.first?.title, Localizations.ok)
        XCTAssertEqual(subject.alertActions.first?.style, .cancel)
    }

    /// `pushNotificationsInformation(action:)` constructs an `Alert` that informs the
    ///  user about receiving push notifications.
    func test_pushNotificationsInformation() {
        let subject = Alert.pushNotificationsInformation {}

        XCTAssertEqual(subject.title, Localizations.enableAutomaticSyncing)
        XCTAssertEqual(subject.message, Localizations.pushNotificationAlert)
        XCTAssertEqual(subject.alertActions.first?.title, Localizations.okGotIt)
        XCTAssertEqual(subject.alertActions.first?.style, .default)
    }
}
