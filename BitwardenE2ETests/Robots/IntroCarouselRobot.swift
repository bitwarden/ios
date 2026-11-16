import XCTest

// MARK: - IntroCarouselRobot

/// The intro carousel, the first screen of an app with no accounts.
///
final class IntroCarouselRobot: Robot {
    // MARK: Properties

    /// The carousel has no accessibility identifiers, so this is the suite's only label lookup.
    private var logInButton: XCUIElement { app.buttons["Log in"] }

    // MARK: Initialization

    /// Creates the robot once the intro carousel is shown.
    ///
    init(app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        super.init(app: app, anchor: app.buttons["Log in"], file: file, line: line)
    }

    // MARK: Methods

    /// Taps the log in button.
    ///
    func tapLogIn() {
        tap(logInButton)
    }
}
