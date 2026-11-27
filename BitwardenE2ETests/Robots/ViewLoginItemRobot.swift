import XCTest

// MARK: - ViewLoginItemRobot

/// The screen showing the details of a login item.
///
final class ViewLoginItemRobot: Robot {
    // MARK: Properties

    private var passwordText: XCUIElement { app.staticTexts["LoginPasswordEntry"] }
    private var showPasswordButton: XCUIElement { app.buttons["ShowLoginPasswordButton"] }
    private var uriTexts: XCUIElementQuery { app.staticTexts.matching(identifier: "LoginUriEntry") }
    private var usernameText: XCUIElement { app.staticTexts["LoginUsernameEntry"] }

    // MARK: Initialization

    /// Creates the robot once the login item is shown.
    ///
    init(app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        super.init(app: app, anchor: app.buttons["ShowLoginPasswordButton"], file: file, line: line)
    }

    // MARK: Methods

    /// Asserts the revealed password.
    ///
    @discardableResult
    func assertPassword(_ password: String, file: StaticString = #filePath, line: UInt = #line) -> Self {
        // The app renders a zero-width space after every character so the password can wrap.
        let shown = text(of: passwordText, file: file, line: line).replacingOccurrences(of: "\u{200B}", with: "")
        XCTAssertEqual(shown, password, file: file, line: line)
        return self
    }

    /// Asserts the password is masked.
    ///
    @discardableResult
    func assertPasswordIsHidden(file: StaticString = #filePath, line: UInt = #line) -> Self {
        let shown = text(of: passwordText, file: file, line: line)
        XCTAssertFalse(shown.isEmpty, file: file, line: line)
        XCTAssertTrue(shown.allSatisfy { $0 == "•" }, "The password isn't masked", file: file, line: line)
        return self
    }

    /// Asserts one of the item's URIs is the given one.
    ///
    @discardableResult
    func assertURIsContain(_ uri: String, file: StaticString = #filePath, line: UInt = #line) -> Self {
        waitFor(uriTexts.firstMatch, file: file, line: line)
        let shown = uriTexts.allElementsBoundByIndex.map(\.label)
        XCTAssertTrue(shown.contains(uri), "\(uri) isn't among the URIs shown: \(shown)", file: file, line: line)
        return self
    }

    /// Asserts the username.
    ///
    @discardableResult
    func assertUsername(_ username: String, file: StaticString = #filePath, line: UInt = #line) -> Self {
        XCTAssertEqual(text(of: usernameText, file: file, line: line), username, file: file, line: line)
        return self
    }

    /// Reveals the password.
    ///
    @discardableResult
    func revealPassword() -> Self {
        tap(showPasswordButton)
        return self
    }
}
