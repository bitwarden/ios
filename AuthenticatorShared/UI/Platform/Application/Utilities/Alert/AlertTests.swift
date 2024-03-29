import BitwardenSdk
import XCTest

@testable import AuthenticatorShared

// MARK: - AlertTests

class AlertTests: AuthenticatorTestCase {
    // MARK: Properties

    var subject: Alert!

    // MARK: Setup and Teardown

    override func setUp() {
        super.setUp()

        subject = Alert(title: "🍎", message: "🥝", preferredStyle: .alert)
            .add(AlertAction(title: "Cancel", style: .cancel))
            .addPreferred(AlertAction(title: "OK", style: .default))
            .add(AlertTextField(
                id: "field",
                autocapitalizationType: .allCharacters,
                autocorrectionType: .no,
                isSecureTextEntry: true,
                keyboardType: .numberPad,
                placeholder: "placeholder",
                text: "value"
            ))
    }

    override func tearDown() {
        super.tearDown()
        subject = nil
    }

    // MARK: Tests

    /// `createAlertController` returns a `UIAlertController` based on the alert details.
    @MainActor
    func test_createAlertController() throws {
        let alertController = subject.createAlertController()

        XCTAssertEqual(alertController.title, "🍎")
        XCTAssertEqual(alertController.message, "🥝")
        XCTAssertEqual(alertController.preferredStyle, .alert)
        XCTAssertEqual(alertController.actions.count, 2)
        XCTAssertEqual(alertController.actions[0].title, "Cancel")
        XCTAssertEqual(alertController.actions[0].style, .cancel)
        XCTAssertEqual(alertController.actions[1].title, "OK")
        XCTAssertEqual(alertController.actions[1].style, .default)
        XCTAssertEqual(alertController.textFields?.count, 1)

        let textField = try XCTUnwrap(alertController.textFields?.first)
        XCTAssertEqual(textField.text, "value")
        XCTAssertEqual(textField.placeholder, "placeholder")
        XCTAssertEqual(textField.autocapitalizationType, .allCharacters)
        XCTAssertEqual(textField.autocorrectionType, .no)
        XCTAssertEqual(textField.isSecureTextEntry, true)
        XCTAssertEqual(textField.keyboardType, .numberPad)
        XCTAssertEqual(alertController.preferredAction?.title, "OK")
    }

    /// `debugDescription` contains the alert's properties
    func test_debugDescription() {
        XCTAssertEqual(
            subject!.debugDescription,
            // swiftlint:disable:next line_length
            "Alert(title: 🍎, message: 🥝, alertActions: [AuthenticatorShared.AlertAction, AuthenticatorShared.AlertAction],"
                + " alertTextFields: [AuthenticatorShared.AlertTextField])"
        )
    }

    /// Alert conforms to `Equatable`.
    func test_equatable() {
        XCTAssertEqual(subject, Alert(title: "🍎", message: "🥝", preferredStyle: .alert)
            .add(AlertAction(title: "Cancel", style: .cancel))
            .addPreferred(AlertAction(title: "OK", style: .default))
            .add(AlertTextField(
                id: "field",
                autocapitalizationType: .allCharacters,
                autocorrectionType: .yes,
                isSecureTextEntry: true,
                keyboardType: .numberPad,
                placeholder: "placeholder",
                text: "value"
            )))
        XCTAssertNotEqual(subject, Alert(title: "🍎", message: "🥝", preferredStyle: .alert)
            .add(AlertAction(title: "Cancel", style: .destructive))
            .addPreferred(AlertAction(title: "OK", style: .default))
            .add(AlertTextField(
                id: "field",
                autocapitalizationType: .allCharacters,
                autocorrectionType: .yes,
                isSecureTextEntry: true,
                keyboardType: .numberPad,
                placeholder: "placeholder",
                text: "value"
            )))
        XCTAssertNotEqual(subject, Alert(title: "🍎", message: "🥝", preferredStyle: .alert))
        XCTAssertNotEqual(subject, Alert(title: "🍎", message: "🥝", preferredStyle: .alert)
            .add(AlertAction(title: "Cancel", style: .cancel))
            .addPreferred(AlertAction(title: "OK", style: .default) { _ in })
            .add(AlertTextField(
                id: "field",
                autocapitalizationType: .allCharacters,
                autocorrectionType: .yes,
                isSecureTextEntry: true,
                keyboardType: .numberPad,
                placeholder: "placeholder",
                text: "value"
            )))
        XCTAssertEqual(subject, Alert(title: "🍎", message: "🥝", preferredStyle: .alert)
            .add(AlertAction(title: "Cancel", style: .cancel))
            .addPreferred(AlertAction(title: "OK", style: .default)))
    }
}
