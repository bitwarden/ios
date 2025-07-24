import BitwardenResources
import SnapshotTesting
import SwiftUI
import ViewInspector
import XCTest

@testable import BitwardenShared

// MARK: - LoginViewTests

class LoginViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<LoginState, LoginAction, LoginEffect>!
    var subject: LoginView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        processor = MockProcessor(state: LoginState())
        let store = Store(processor: processor)
        subject = LoginView(store: store)
    }

    override func tearDown() {
        super.tearDown()
        processor = nil
        subject = nil
    }

    // MARK: Tests

    /// Tapping the login button dispatches the `.loginWithMasterPasswordPressed` action.
    @MainActor
    func test_loginButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.logInWithMasterPassword)
        try button.tap()
        waitFor(!processor.effects.isEmpty)
        XCTAssertEqual(processor.effects.last, .loginWithMasterPasswordPressed)
    }

    /// Tapping the enterprise single sign-on button dispatches the `.enterpriseSingleSignOnPressed` action.
    @MainActor
    func test_enterpriseSingleSignOnButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.logInSso)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .enterpriseSingleSignOnPressed)
    }

    /// Tapping the not you button dispatches the `.notYouPressed` action.
    @MainActor
    func test_notYouButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.notYou)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .notYouPressed)
    }

    /// Tapping the get master password hint button dispatches the `.getMasterPasswordHintPressed` action.
    @MainActor
    func test_getMasterPasswordHintButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.getMasterPasswordwordHint)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .getMasterPasswordHintPressed)
    }

    /// The login with device button should not be visible when `isLoginWithDeviceVisible` is `false`.
    @MainActor
    func test_loginWithDeviceButton_isLoginWithDeviceVisible_false() {
        processor.state.isLoginWithDeviceVisible = false
        XCTAssertThrowsError(try subject.inspect().find(button: Localizations.logInWithDevice))
    }

    /// The login with device button should be visible when `isLoginWithDeviceVisible` is `true`.
    @MainActor
    func test_loginWithDeviceButton_isLoginWithDeviceVisible_true() {
        processor.state.isLoginWithDeviceVisible = true
        XCTAssertNoThrow(try subject.inspect().find(button: Localizations.logInWithDevice))
    }

    /// Tapping the login with device button dispatches the `.loginWithDevicePressed` action.
    @MainActor
    func test_loginWithDeviceButton_tap() throws {
        processor.state.isLoginWithDeviceVisible = true
        let button = try subject.inspect().find(button: Localizations.logInWithDevice)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .loginWithDevicePressed)
    }

    /// The secure field is visible when `isMasterPasswordRevealed` is `false`.
    @MainActor
    func test_isMasterPasswordRevealed_false() throws {
        processor.state.isMasterPasswordRevealed = false
        XCTAssertNoThrow(try subject.inspect().find(secureField: ""))
        let textField = try subject.inspect().find(textField: "")
        XCTAssertTrue(textField.isHidden())
    }

    /// The text field is visible when `isMasterPasswordRevealed` is `true`.
    @MainActor
    func test_isMasterPasswordRevealed_true() {
        processor.state.isMasterPasswordRevealed = true
        XCTAssertNoThrow(try subject.inspect().find(textField: ""))
        XCTAssertThrowsError(try subject.inspect().find(secureField: ""))
    }

    /// Updating the text field dispatches the `.masterPasswordChanged()` action.
    @MainActor
    func test_textField_updateValue() throws {
        processor.state.isMasterPasswordRevealed = true
        let textField = try subject.inspect().find(textField: "")
        try textField.setInput("text")
        XCTAssertEqual(processor.dispatchedActions.last, .masterPasswordChanged("text"))
    }

    /// Updating the secure field dispatches the `.masterPasswordChanged()` action.
    @MainActor
    func test_secureField_updateValue() throws {
        processor.state.isMasterPasswordRevealed = false
        let secureField = try subject.inspect().find(secureField: "")
        try secureField.setInput("text")
        XCTAssertEqual(processor.dispatchedActions.last, .masterPasswordChanged("text"))
    }

    // MARK: Snapshots

    @MainActor
    func test_snapshot_empty() {
        processor.state.username = "user@bitwarden.com"
        processor.state.serverURLString = "bitwarden.com"
        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    @MainActor
    func test_snapshot_passwordHidden() {
        processor.state.username = "user@bitwarden.com"
        processor.state.masterPassword = "Password"
        processor.state.serverURLString = "bitwarden.com"
        processor.state.isMasterPasswordRevealed = false
        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    @MainActor
    func test_snapshot_passwordRevealed() {
        processor.state.username = "user@bitwarden.com"
        processor.state.masterPassword = "Password"
        processor.state.serverURLString = "bitwarden.com"
        processor.state.isMasterPasswordRevealed = true
        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    @MainActor
    func test_snapshot_selfHosted() {
        processor.state.username = "user@bitwarden.com"
        processor.state.serverURLString = "selfhostedserver.com"
        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    @MainActor
    func test_snapshot_withDevice() {
        processor.state.username = "user@bitwarden.com"
        processor.state.isLoginWithDeviceVisible = true
        processor.state.serverURLString = "bitwarden.com"
        assertSnapshot(of: subject, as: .defaultPortrait)
    }
}
