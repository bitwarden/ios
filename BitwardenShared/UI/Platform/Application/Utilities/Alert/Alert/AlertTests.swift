import BitwardenResources
import BitwardenSdk
import XCTest

@testable import BitwardenShared

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
        let rootViewController = UIViewController()
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
            "Alert(title: 🍎, message: 🥝, alertActions: [BitwardenShared.AlertAction, BitwardenShared.AlertAction],"
                + " alertTextFields: [BitwardenShared.AlertTextField])"
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

    @MainActor
    func test_vault_moreOptions_login_canViewPassword() async throws { // swiftlint:disable:this function_body_length
        var capturedAction: MoreOptionsAction?
        let action: (MoreOptionsAction) -> Void = { action in
            capturedAction = action
        }
        let cipher = CipherView.fixture(
            edit: false,
            id: "123",
            login: .fixture(
                password: "password",
                username: "username"
            ),
            name: "Test Cipher",
            type: .login,
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
        XCTAssertEqual(alert.alertActions.count, 5)

        // Test the first action is a view action.
        let first = try XCTUnwrap(alert.alertActions[0])
        XCTAssertEqual(first.title, Localizations.view)
        await first.handler?(first, [])
        XCTAssertEqual(capturedAction, .view(id: "123"))
        capturedAction = nil

        // Test the second action is edit.
        let second = try XCTUnwrap(alert.alertActions[1])
        XCTAssertEqual(second.title, Localizations.edit)
        await second.handler?(second, [])
        XCTAssertEqual(
            capturedAction,
            .edit(cipherView: cipher)
        )
        capturedAction = nil

        // Test the third action is copy username.
        let third = try XCTUnwrap(alert.alertActions[2])
        XCTAssertEqual(third.title, Localizations.copyUsername)
        await third.handler?(third, [])
        XCTAssertEqual(
            capturedAction,
            .copy(
                toast: Localizations.username,
                value: "username",
                requiresMasterPasswordReprompt: false,
                logEvent: nil,
                cipherId: nil
            )
        )
        capturedAction = nil

        // Test the fourth action is copy password.
        let fourth = try XCTUnwrap(alert.alertActions[3])
        XCTAssertEqual(fourth.title, Localizations.copyPassword)
        await fourth.handler?(fourth, [])
        XCTAssertEqual(
            capturedAction,
            .copy(
                toast: Localizations.password,
                value: "password",
                requiresMasterPasswordReprompt: true,
                logEvent: .cipherClientCopiedPassword,
                cipherId: "123"
            )
        )
        capturedAction = nil

        // Test the fifth action is a cancel action.
        let fifth = try XCTUnwrap(alert.alertActions[4])
        XCTAssertEqual(fifth.title, Localizations.cancel)
        await fifth.handler?(fifth, [])
        XCTAssertNil(capturedAction)
    }

    @MainActor
    func test_vault_moreOptions_login_cannotViewPassword() async throws {
        var capturedAction: MoreOptionsAction?
        let action: (MoreOptionsAction) -> Void = { action in
            capturedAction = action
        }
        let cipher = CipherView.fixture(
            edit: false,
            id: "123",
            login: .fixture(
                password: "password",
                username: nil
            ),
            name: "Test Cipher",
            type: .login,
            viewPassword: false
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
        XCTAssertEqual(alert.alertActions.count, 3)

        // Test the first action is a view action.
        let first = try XCTUnwrap(alert.alertActions[0])
        XCTAssertEqual(first.title, Localizations.view)
        await first.handler?(first, [])
        XCTAssertEqual(capturedAction, .view(id: "123"))
        capturedAction = nil

        // Test the second action is edit.
        let second = try XCTUnwrap(alert.alertActions[1])
        XCTAssertEqual(second.title, Localizations.edit)
        await second.handler?(second, [])
        XCTAssertEqual(
            capturedAction,
            .edit(cipherView: cipher)
        )
        capturedAction = nil

        // Test the third action is a cancel action.
        let third = try XCTUnwrap(alert.alertActions[2])
        XCTAssertEqual(third.title, Localizations.cancel)
        await third.handler?(third, [])
        XCTAssertNil(capturedAction)
    }
}
