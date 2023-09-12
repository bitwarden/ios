import SwiftUI
import ViewInspector
import XCTest

@testable import BitwardenShared

// MARK: - LoginViewTests

class LoginViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<LoginState, LoginAction, Void>!
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
    func test_loginButton_tap() throws {
        let button = try subject.inspect().find(button: "Log in with master password")
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .loginWithMasterPasswordPressed)
    }

    /// Tapping the enterprise single sign-on button dispatches the `.enterpriseSingleSignOnPressed` action.
    func test_enterpriseSingleSignOnButton_tap() throws {
        let button = try subject.inspect().find(button: "Enterprise single sign-on")
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .enterpriseSingleSignOnPressed)
    }

    /// Tapping the not you button dispatches the `.notYouPressed` action.
    func test_notYouButton_tap() throws {
        let button = try subject.inspect().find(button: "Not you?")
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .notYouPressed)
    }

    /// Tapping the get master password hint button dispatches the `.getMasterPasswordHintPressed` action.
    func test_getMasterPasswordHintButton_tap() throws {
        let button = try subject.inspect().find(button: "Get master password hint")
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .getMasterPasswordHintPressed)
    }

    /// Tapping the options button in the nav bar dispatches the `.morePressed` action.
    func test_moreButton_tap() throws {
        let button = try subject.inspect().find(button: "Options")
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .morePressed)
    }

    /// The login with device button should not be visible when `isLoginWithDeviceEnabled` is `false`.
    func test_loginWithDeviceButton_isLoginWithDeviceEnabled_false() {
        processor.state.isLoginWithDeviceEnabled = false
        XCTAssertThrowsError(try subject.inspect().find(button: "Login with device"))
    }

    /// The login with device button should be visible when `isLoginWithDeviceEnabled` is `true`.
    func test_loginWithDeviceButton_isLoginWithDeviceEnabled_true() {
        processor.state.isLoginWithDeviceEnabled = true
        XCTAssertNoThrow(try subject.inspect().find(button: "Login with device"))
    }

    /// Tapping the login with device button dispatches the `.loginWithDevicePressed` action.
    func test_loginWithDeviceButton_tap() throws {
        processor.state.isLoginWithDeviceEnabled = true
        let button = try subject.inspect().find(button: "Login with device")
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .loginWithDevicePressed)
    }

    /// Tapping the reveal master password button dispatches the `.revealMasterPasswordFieldPressed` action.
    func test_revealMasterPasswordButton_tap() throws {
        let button = try subject.inspect().find(buttonWithId: "revealMasterPassword")
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .revealMasterPasswordFieldPressed)
    }

    /// The secure field is visible when `isMasterPasswordRevealed` is `false`.
    func test_isMasterPasswordRevealed_false() {
        processor.state.isMasterPasswordRevealed = false
        XCTAssertThrowsError(try subject.inspect().find(textField: "Master Password"))
        XCTAssertNoThrow(try subject.inspect().find(secureField: "Master Password"))
    }

    /// The text field is visible when `isMasterPasswordRevealed` is `true`.
    func test_isMasterPasswordRevealed_true() {
        processor.state.isMasterPasswordRevealed = true
        XCTAssertNoThrow(try subject.inspect().find(textField: "Master Password"))
        XCTAssertThrowsError(try subject.inspect().find(secureField: "Master Password"))
    }

    /// Updating the text field dispatches the `.masterPasswordChanged()` action.
    func test_textField_updateValue() throws {
        processor.state.isMasterPasswordRevealed = true
        let textField = try subject.inspect().find(textField: "Master Password")
        try textField.setInput("text")
        XCTAssertEqual(processor.dispatchedActions.last, .masterPasswordChanged("text"))
    }

    /// Updating the secure field dispatches the `.masterPasswordChanged()` action.
    func test_secureField_updateValue() throws {
        processor.state.isMasterPasswordRevealed = false
        let secureField = try subject.inspect().find(secureField: "Master Password")
        try secureField.setInput("text")
        XCTAssertEqual(processor.dispatchedActions.last, .masterPasswordChanged("text"))
    }
}
