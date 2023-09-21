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
        let button = try subject.inspect().find(button: Localizations.logInWithMasterPassword)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .loginWithMasterPasswordPressed)
    }

    /// Tapping the enterprise single sign-on button dispatches the `.enterpriseSingleSignOnPressed` action.
    func test_enterpriseSingleSignOnButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.logInSso)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .enterpriseSingleSignOnPressed)
    }

    /// Tapping the not you button dispatches the `.notYouPressed` action.
    func test_notYouButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.notYou)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .notYouPressed)
    }

    /// Tapping the get master password hint button dispatches the `.getMasterPasswordHintPressed` action.
    func test_getMasterPasswordHintButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.getMasterPasswordwordHint)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .getMasterPasswordHintPressed)
    }

    /// Tapping the options button in the nav bar dispatches the `.morePressed` action.
    func test_moreButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.options)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .morePressed)
    }

    /// The login with device button should not be visible when `isLoginWithDeviceVisible` is `false`.
    func test_loginWithDeviceButton_isLoginWithDeviceVisible_false() {
        processor.state.isLoginWithDeviceVisible = false
        XCTAssertThrowsError(try subject.inspect().find(button: Localizations.logInWithDevice))
    }

    /// The login with device button should be visible when `isLoginWithDeviceVisible` is `true`.
    func test_loginWithDeviceButton_isLoginWithDeviceVisible_true() {
        processor.state.isLoginWithDeviceVisible = true
        XCTAssertNoThrow(try subject.inspect().find(button: Localizations.logInWithDevice))
    }

    /// Tapping the login with device button dispatches the `.loginWithDevicePressed` action.
    func test_loginWithDeviceButton_tap() throws {
        processor.state.isLoginWithDeviceVisible = true
        let button = try subject.inspect().find(button: Localizations.logInWithDevice)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .loginWithDevicePressed)
    }

    /// The secure field is visible when `isMasterPasswordRevealed` is `false`.
    func test_isMasterPasswordRevealed_false() throws {
        processor.state.isMasterPasswordRevealed = false
        XCTAssertNoThrow(try subject.inspect().find(secureField: ""))
        let textField = try subject.inspect().find(textField: "")
        XCTAssertTrue(textField.isHidden())
    }

    /// The text field is visible when `isMasterPasswordRevealed` is `true`.
    func test_isMasterPasswordRevealed_true() {
        processor.state.isMasterPasswordRevealed = true
        XCTAssertNoThrow(try subject.inspect().find(textField: ""))
        XCTAssertThrowsError(try subject.inspect().find(secureField: ""))
    }

    /// Updating the text field dispatches the `.masterPasswordChanged()` action.
    func test_textField_updateValue() throws {
        processor.state.isMasterPasswordRevealed = true
        let textField = try subject.inspect().find(textField: "")
        try textField.setInput("text")
        XCTAssertEqual(processor.dispatchedActions.last, .masterPasswordChanged("text"))
    }

    /// Updating the secure field dispatches the `.masterPasswordChanged()` action.
    func test_secureField_updateValue() throws {
        processor.state.isMasterPasswordRevealed = false
        let secureField = try subject.inspect().find(secureField: "")
        try secureField.setInput("text")
        XCTAssertEqual(processor.dispatchedActions.last, .masterPasswordChanged("text"))
    }
}
