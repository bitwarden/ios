// swiftlint:disable:this file_name

import BitwardenResources
import XCTest

@testable import BitwardenShared

// MARK: - AlertExtensionTests

class AlertExtensionsTests: BitwardenTestCase {
    // MARK: Tests

    func test_invalidEmail() {
        let subject = Alert.invalidEmail

        XCTAssertEqual(subject.title, Localizations.anErrorHasOccurred)
        XCTAssertEqual(subject.message, Localizations.invalidEmail)
        XCTAssertEqual(subject.preferredStyle, .alert)
        XCTAssertEqual(subject.alertActions.count, 1)

        let action = subject.alertActions[0]
        XCTAssertEqual(action.title, Localizations.ok)
        XCTAssertEqual(action.style, .default)
        XCTAssertNil(action.handler)
    }

    /// `nameCustomFieldAlert` disables the "OK" button when the text field is empty,
    /// and enables it dynamically when the user enters text.
    @MainActor
    func test_nameCustomFieldAlert_enablesOkButtonWhenTextIsEntered() throws {
        let alert = Alert.nameCustomFieldAlert(text: "") { _ in }
        let controller = alert.createAlertController()

        let uiTextField = try XCTUnwrap(controller.textFields?.first)
        let okAction = try XCTUnwrap(
            controller.actions.first(where: { $0.title == Localizations.ok }))

        XCTAssertFalse(okAction.isEnabled)

        uiTextField.text = "some value"
        alert.alertTextFields.first?.textChanged(in: uiTextField)

        XCTAssertTrue(okAction.isEnabled)
    }
}
