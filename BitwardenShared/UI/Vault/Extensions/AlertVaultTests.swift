import BitwardenResources
import BitwardenSdk
import XCTest

@testable import BitwardenShared

class AlertVaultTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    /// `cipherDecryptionFailure()` returns an `Alert` to notify the user that an item in their
    /// vault was unable to be decrypted for when a cipher which failed to decrypt is tapped.
    func test_cipherDecryptionFailure() async throws {
        var copyString: String?
        let subject = Alert.cipherDecryptionFailure(cipherIds: ["123abc"]) { copyString = $0 }

        XCTAssertEqual(subject.title, Localizations.decryptionError)
        XCTAssertEqual(
            subject.message,
            Localizations.bitwardenCouldNotDecryptThisVaultItemDescriptionLong
        )
        XCTAssertEqual(subject.alertActions.count, 2)
        XCTAssertEqual(subject.alertActions[0].title, Localizations.copyErrorReport)
        XCTAssertEqual(subject.alertActions[0].style, .default)
        XCTAssertEqual(subject.alertActions[1].title, Localizations.close)
        XCTAssertEqual(subject.alertActions[1].style, .cancel)

        try await subject.tapAction(title: Localizations.copyErrorReport)
        XCTAssertEqual(
            copyString,
            """
            \(Localizations.decryptionError)
            \(Localizations.bitwardenCouldNotDecryptThisVaultItemDescriptionLong)

            123abc
            """
        )
    }

    /// `cipherDecryptionFailure()` returns an `Alert` to notify the user that an item in their
    /// vault was unable to be decrypted.
    func test_cipherDecryptionFailure_isFromCipherTypeFalse() async throws {
        var copyString: String?
        let subject = Alert.cipherDecryptionFailure(
            cipherIds: ["123abc"],
            isFromCipherTap: false
        ) { stringToCopy in
            copyString = stringToCopy
        }

        XCTAssertEqual(subject.title, Localizations.decryptionError)
        XCTAssertEqual(
            subject.message,
            Localizations.bitwardenCouldNotDecryptOneVaultItemDescriptionLong
        )
        XCTAssertEqual(subject.alertActions.count, 2)
        XCTAssertEqual(subject.alertActions[0].title, Localizations.copyErrorReport)
        XCTAssertEqual(subject.alertActions[0].style, .default)
        XCTAssertEqual(subject.alertActions[1].title, Localizations.close)
        XCTAssertEqual(subject.alertActions[1].style, .cancel)

        try await subject.tapAction(title: Localizations.copyErrorReport)
        XCTAssertEqual(
            copyString,
            """
            \(Localizations.decryptionError)
            \(Localizations.bitwardenCouldNotDecryptOneVaultItemDescriptionLong)

            123abc
            """
        )
    }

    /// `cipherDecryptionFailure()` returns an `Alert` to notify the user that multiple items in
    /// their vault were unable to be decrypted.
    func test_cipherDecryptionFailure_isFromCipherTypeFalse_multipleIds() async throws {
        var copyString: String?
        let subject = Alert.cipherDecryptionFailure(
            cipherIds: ["123abc", "789xyz"],
            isFromCipherTap: false
        ) { stringToCopy in
            copyString = stringToCopy
        }

        XCTAssertEqual(subject.title, Localizations.decryptionError)
        XCTAssertEqual(
            subject.message,
            Localizations.bitwardenCouldNotDecryptXVaultItemsDescriptionLong(2)
        )
        XCTAssertEqual(subject.alertActions.count, 2)
        XCTAssertEqual(subject.alertActions[0].title, Localizations.copyErrorReport)
        XCTAssertEqual(subject.alertActions[0].style, .default)
        XCTAssertEqual(subject.alertActions[1].title, Localizations.close)
        XCTAssertEqual(subject.alertActions[1].style, .cancel)

        try await subject.tapAction(title: Localizations.copyErrorReport)
        XCTAssertEqual(
            copyString,
            """
            \(Localizations.decryptionError)
            \(Localizations.bitwardenCouldNotDecryptXVaultItemsDescriptionLong(2))

            123abc
            789xyz
            """
        )
    }

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

    /// `importLoginsComputerAvailable(action:)` constructs an `Alert` that confirms that the user
    /// has a computer available to import logins.
    func test_importLoginsComputerAvailable() async throws {
        var actionCalled = false
        let subject = Alert.importLoginsComputerAvailable { actionCalled = true }

        XCTAssertEqual(subject.title, Localizations.doYouHaveAComputerAvailable)
        XCTAssertEqual(subject.message, Localizations.doYouHaveAComputerAvailableDescriptionLong)
        XCTAssertEqual(subject.alertActions[0].title, Localizations.cancel)
        XCTAssertEqual(subject.alertActions[0].style, .cancel)
        XCTAssertEqual(subject.alertActions[1].title, Localizations.continue)
        XCTAssertEqual(subject.alertActions[1].style, .default)

        try await subject.tapCancel()
        XCTAssertFalse(actionCalled)

        try await subject.tapAction(title: Localizations.continue)
        XCTAssertTrue(actionCalled)
    }

    /// `importLoginsEmpty(action:)` constructs an `Alert` that informs the user that no logins
    /// were imported.
    func test_importLoginsEmpty() async throws {
        var actionCalled = false
        let subject = Alert.importLoginsEmpty { actionCalled = true }

        XCTAssertEqual(subject.title, Localizations.importError)
        XCTAssertEqual(subject.message, Localizations.noLoginsWereImported)
        XCTAssertEqual(subject.alertActions[0].title, Localizations.tryAgain)
        XCTAssertEqual(subject.alertActions[0].style, .cancel)
        XCTAssertEqual(subject.alertActions[1].title, Localizations.importLoginsLater)
        XCTAssertEqual(subject.alertActions[1].style, .default)

        try await subject.tapAction(title: Localizations.tryAgain)
        XCTAssertFalse(actionCalled)

        try await subject.tapAction(title: Localizations.importLoginsLater)
        XCTAssertTrue(actionCalled)
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

    /// `static moreOptions(canCopyTotp:cipherView:hasMasterPassword:id:showEdit:action:)` returns
    /// the appropirate options for `.sshKey` type
    @MainActor
    func test_moreOptions_sshKey() async throws { // swiftlint:disable:this function_body_length
        var capturedAction: MoreOptionsAction?
        let action: (MoreOptionsAction) -> Void = { action in
            capturedAction = action
        }
        let cipher = CipherView.fixture(
            edit: false,
            id: "123",
            name: "Test Cipher",
            sshKey: .fixture(),
            type: .sshKey,
            viewPassword: true
        )
        let alert = Alert.moreOptions(
            canCopyTotp: false,
            cipherView: cipher,
            id: cipher.id!,
            showEdit: true,
            action: action
        )
        XCTAssertEqual(alert.title, cipher.name)
        XCTAssertEqual(alert.preferredStyle, .actionSheet)
        XCTAssertEqual(alert.alertActions.count, 6)

        try await alert.tapAction(byIndex: 0, withTitle: Localizations.view)
        XCTAssertEqual(capturedAction, .view(id: "123"))
        capturedAction = nil

        try await alert.tapAction(byIndex: 1, withTitle: Localizations.edit)
        XCTAssertEqual(
            capturedAction,
            .edit(cipherView: cipher)
        )
        capturedAction = nil

        try await alert.tapAction(byIndex: 2, withTitle: Localizations.copyPublicKey)
        XCTAssertEqual(
            capturedAction,
            .copy(
                toast: Localizations.publicKey,
                value: "publicKey",
                requiresMasterPasswordReprompt: true,
                logEvent: nil,
                cipherId: "123"
            )
        )
        capturedAction = nil

        try await alert.tapAction(byIndex: 3, withTitle: Localizations.copyPrivateKey)
        XCTAssertEqual(
            capturedAction,
            .copy(
                toast: Localizations.privateKey,
                value: "privateKey",
                requiresMasterPasswordReprompt: true,
                logEvent: nil,
                cipherId: "123"
            )
        )
        capturedAction = nil

        try await alert.tapAction(byIndex: 4, withTitle: Localizations.copyFingerprint)
        XCTAssertEqual(
            capturedAction,
            .copy(
                toast: Localizations.fingerprint,
                value: "fingerprint",
                requiresMasterPasswordReprompt: true,
                logEvent: nil,
                cipherId: "123"
            )
        )
        capturedAction = nil

        try await alert.tapAction(byIndex: 5, withTitle: Localizations.cancel)
        XCTAssertNil(capturedAction)
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
