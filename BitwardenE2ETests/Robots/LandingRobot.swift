import XCTest

// MARK: - LandingRobot

/// The landing screen, where the email is entered.
///
final class LandingRobot: Robot {
    // MARK: Properties

    private var continueButton: XCUIElement { app.buttons["ContinueButton"] }
    private var emailField: XCUIElement { app.textFields["LoginEmailAddressEntry"] }

    // MARK: Initialization

    /// Creates the robot once the landing screen is shown.
    ///
    init(app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        super.init(app: app, anchor: app.textFields["LoginEmailAddressEntry"], file: file, line: line)
    }

    // MARK: Methods

    /// Types the email.
    ///
    @discardableResult
    func enterEmail(_ email: String) -> Self {
        type(email, into: emailField)
        return self
    }

    /// Submits the email with the continue button.
    ///
    func submitEmail() {
        tap(continueButton)
    }
}
