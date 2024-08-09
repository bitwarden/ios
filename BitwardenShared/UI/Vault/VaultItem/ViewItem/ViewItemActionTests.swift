import XCTest

@testable import BitwardenShared

class ViewItemActionTests: BitwardenTestCase {
    // MARK: Tests

    /// `eventOnCopy` returns the event to collect for the field.
    func test_eventOnCopy() {
        XCTAssertNil(CopyableField.cardNumber.eventOnCopy)
        XCTAssertEqual(CopyableField.customHiddenField.eventOnCopy, .cipherClientCopiedHiddenField)
        XCTAssertNil(CopyableField.customTextField.eventOnCopy)
        XCTAssertEqual(CopyableField.password.eventOnCopy, .cipherClientCopiedPassword)
        XCTAssertEqual(CopyableField.securityCode.eventOnCopy, .cipherClientCopiedCardCode)
        XCTAssertNil(CopyableField.totp.eventOnCopy)
        XCTAssertNil(CopyableField.uri.eventOnCopy)
        XCTAssertNil(CopyableField.username.eventOnCopy)
    }

    /// `requiresMasterPasswordReprompt` returns whether the user's master password needs to be
    /// entered again before performing the action if master password reprompt is enabled.
    func test_requiresMasterPasswordReprompt() {
        XCTAssertTrue(ViewItemAction.cardItemAction(.toggleCodeVisibilityChanged(false)).requiresMasterPasswordReprompt)

        XCTAssertTrue(ViewItemAction.copyPressed(value: "", field: .cardNumber).requiresMasterPasswordReprompt)
        XCTAssertTrue(ViewItemAction.copyPressed(value: "", field: .customHiddenField).requiresMasterPasswordReprompt)
        XCTAssertFalse(ViewItemAction.copyPressed(value: "", field: .customTextField).requiresMasterPasswordReprompt)
        XCTAssertTrue(ViewItemAction.copyPressed(value: "", field: .password).requiresMasterPasswordReprompt)
        XCTAssertTrue(ViewItemAction.copyPressed(value: "", field: .securityCode).requiresMasterPasswordReprompt)
        XCTAssertTrue(ViewItemAction.copyPressed(value: "", field: .totp).requiresMasterPasswordReprompt)
        XCTAssertFalse(ViewItemAction.copyPressed(value: "", field: .uri).requiresMasterPasswordReprompt)
        XCTAssertFalse(ViewItemAction.copyPressed(value: "", field: .username).requiresMasterPasswordReprompt)

        XCTAssertTrue(
            ViewItemAction.customFieldVisibilityPressed(CustomFieldState(id: "1", type: .hidden))
                .requiresMasterPasswordReprompt
        )

        XCTAssertFalse(ViewItemAction.dismissPressed.requiresMasterPasswordReprompt)

        XCTAssertFalse(ViewItemAction.downloadAttachment(.fixture()).requiresMasterPasswordReprompt)

        XCTAssertTrue(ViewItemAction.editPressed.requiresMasterPasswordReprompt)

        XCTAssertTrue(ViewItemAction.morePressed(.attachments).requiresMasterPasswordReprompt)
        XCTAssertTrue(ViewItemAction.morePressed(.clone).requiresMasterPasswordReprompt)
        XCTAssertTrue(ViewItemAction.morePressed(.editCollections).requiresMasterPasswordReprompt)
        XCTAssertTrue(ViewItemAction.morePressed(.moveToOrganization).requiresMasterPasswordReprompt)

        XCTAssertFalse(ViewItemAction.passwordHistoryPressed.requiresMasterPasswordReprompt)

        XCTAssertTrue(ViewItemAction.passwordVisibilityPressed.requiresMasterPasswordReprompt)

        XCTAssertFalse(ViewItemAction.toastShown(nil).requiresMasterPasswordReprompt)
    }
}
