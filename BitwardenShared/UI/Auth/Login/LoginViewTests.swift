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

    func test_enterpriseSignSignOnButton_tap() throws {
        let button = try subject.inspect().find(button: "Enterprise single sign-on")
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .enterpriseSingleSignOnPressed)
    }

    func test_notYouButton_tap() throws {
        let button = try subject.inspect().find(button: "Not you?")
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .notYouPressed)
    }

    func test_getMasterPasswordHintButton_tap() throws {
        let button = try subject.inspect().find(button: "Get master password hint")
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .getMasterPasswordHintPressed)
    }

    func test_moreButton_tap() throws {
        let button = try subject.inspect().find(button: "Options")
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .morePressed)
    }

    func test_loginWithDeviceButton_isLoginWithDeviceEnabled_false() {
        processor.state.isLoginWithDeviceEnabled = false
        XCTAssertThrowsError(try subject.inspect().find(button: "Login with device"))
    }

    func test_loginWithDeviceButton_isLoginWithDeviceEnabled_true() {
        processor.state.isLoginWithDeviceEnabled = true
        XCTAssertNoThrow(try subject.inspect().find(button: "Login with device"))
    }

    func test_loginWithDeviceButton_tap() throws {
        processor.state.isLoginWithDeviceEnabled = true
        let button = try subject.inspect().find(button: "Login with device")
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .loginWithDevicePressed)
    }

    func test_revealMasterPasswordButton_tap() throws {
        let button = try subject.inspect().find(buttonWithId: "revealMasterPassword")
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .revealMasterPasswordFieldPressed)
    }

    func test_isMasterPasswordRevealed_false() {
        processor.state.isMasterPasswordRevealed = false
        XCTAssertThrowsError(try subject.inspect().find(textField: "Master Password"))
        XCTAssertNoThrow(try subject.inspect().find(secureField: "Master Password"))
    }

    func test_isMasterPasswordRevealed_true() {
        processor.state.isMasterPasswordRevealed = true
        XCTAssertNoThrow(try subject.inspect().find(textField: "Master Password"))
        XCTAssertThrowsError(try subject.inspect().find(secureField: "Master Password"))
    }

    func test_textField_updateValue() throws {
        processor.state.isMasterPasswordRevealed = true
        let textField = try subject.inspect().find(textField: "Master Password")
        try textField.setInput("text")
        XCTAssertEqual(processor.dispatchedActions.last, .masterPasswordChanged("text"))
    }

    func test_secureField_updateValue() throws {
        processor.state.isMasterPasswordRevealed = false
        let secureField = try subject.inspect().find(secureField: "Master Password")
        try secureField.setInput("text")
        XCTAssertEqual(processor.dispatchedActions.last, .masterPasswordChanged("text"))
    }
}
