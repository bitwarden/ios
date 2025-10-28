import BitwardenKitMocks
import BitwardenResources
import XCTest

@testable import BitwardenKit

// MARK: - AlertTests

class AlertTests: BitwardenTestCase {
    // MARK: Properties

    var subject: Alert!

    // MARK: Setup and Teardown

    override func setUp() {
        super.setUp()

        subject = Alert.fixture(alertActions: [AlertAction.cancel()],
                                alertTextFields: [AlertTextField.fixture(autocorrectionType: .no)])
            .addPreferred(AlertAction.ok())
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

    /// `createAlertController` sets an `onDismissed` closure that's called when the alert is dismissed.
    @MainActor
    func test_createAlertController_onDismissed() {
        var dismissedCalled = false
        let alertController = subject.createAlertController { dismissedCalled = true }
        let rootViewController = MockUIViewController()
        setKeyWindowRoot(viewController: rootViewController)

        rootViewController.present(alertController, animated: false)
        XCTAssertFalse(dismissedCalled)
        rootViewController.dismiss(animated: false)
        waitFor(rootViewController.presentedViewController == nil)
        XCTAssertTrue(dismissedCalled)
    }

    /// `debugDescription` contains the alert's properties
    func test_debugDescription() {
        XCTAssertEqual(
            subject!.debugDescription,
            "Alert(title: 🍎, message: 🥝, alertActions: [BitwardenKit.AlertAction, BitwardenKit.AlertAction],"
                + " alertTextFields: [BitwardenKit.AlertTextField])",
        )
    }

    /// Alert conforms to `Equatable`.
    func test_equatable() {
        XCTAssertEqual(subject, Alert.fixture(alertActions: [AlertAction.cancel()])
            .addPreferred(AlertAction.ok()))
        XCTAssertNotEqual(subject, Alert.fixture(alertActions: [AlertAction.cancel(style: .destructive)])
            .addPreferred(AlertAction.ok()))
        XCTAssertNotEqual(subject, Alert(title: "🍎", message: "🥝", preferredStyle: .alert))
        XCTAssertNotEqual(subject, Alert.fixture(alertActions: [AlertAction.cancel()])
            .addPreferred(AlertAction.ok { _, _ in }))
        XCTAssertEqual(subject, Alert.fixture(alertActions: [AlertAction.cancel()])
            .addPreferred(AlertAction.ok()))
    }
}
