import XCTest

// MARK: - LoginRobot

/// The login screen, where the master password is entered.
///
final class LoginRobot: Robot {
    // MARK: Properties

    private var logInButton: XCUIElement { app.buttons["LogInWithMasterPasswordButton"] }
    private var masterPasswordField: XCUIElement { app.secureTextFields["LoginMasterPasswordEntry"] }

    // MARK: Initialization

    /// Creates the robot once the login screen is shown.
    ///
    init(app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        super.init(app: app, anchor: app.secureTextFields["LoginMasterPasswordEntry"], file: file, line: line)
    }

    // MARK: Methods

    /// Types the master password.
    ///
    @discardableResult
    func enterMasterPassword(_ password: String) -> Self {
        type(password, into: masterPasswordField)
        return self
    }

    /// Taps the log in button.
    ///
    func tapLogIn() {
        tap(logInButton)
    }
}
