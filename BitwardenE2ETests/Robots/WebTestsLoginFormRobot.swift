import XCTest

// MARK: - WebTestsLoginFormRobot

/// The simple login form on webtests.dev, the public host of Bitwarden's test-the-web. Submitting
/// it shows the submitted values.
///
final class WebTestsLoginFormRobot: SafariRobot {
    // MARK: Properties

    private var usernameField: XCUIElement { app.webViews.textFields.firstMatch }

    // MARK: Methods

    /// Opens the form in Safari.
    ///
    static func open(file: StaticString = #filePath, line: UInt = #line) -> WebTestsLoginFormRobot {
        let url = URL(string: "https://webtests.dev/forms/login/simple/")!
        let safari = openSafari(at: url, file: file, line: line)
        return WebTestsLoginFormRobot(
            app: safari,
            anchor: safari.webViews.textFields.firstMatch,
            file: file,
            line: line,
        )
    }

    /// Asserts the page shows the given values as the submitted form. It's the only place the
    /// filled password is readable.
    ///
    @discardableResult
    func assertSubmitted(
        username: String,
        password: String,
        file: StaticString = #filePath,
        line: UInt = #line,
    ) -> Self {
        waitForPageText("label CONTAINS %@", "\"username\": \"\(username)\"", file: file, line: line)
        waitForPageText("label CONTAINS %@", "\"password\": \"\(password)\"", file: file, line: line)
        return self
    }

    /// Asserts the username field holds the given value.
    ///
    @discardableResult
    func assertUsername(_ username: String, file: StaticString = #filePath, line: UInt = #line) -> Self {
        XCTAssertTrue(
            usernameField.hasOrGetsValue(username, within: E2ETimeouts.element),
            "The username field is \(String(describing: usernameField.value))",
            file: file,
            line: line,
        )
        return self
    }

    /// Focuses the username field, which brings up the keyboard's AutoFill bar.
    ///
    func focusUsername(file: StaticString = #filePath, line: UInt = #line) {
        focus(usernameField, file: file, line: line)
    }

    /// Submits the form.
    ///
    @discardableResult
    func submit(file: StaticString = #filePath, line: UInt = #line) -> Self {
        tapPageButton("Login", file: file, line: line)
        return self
    }
}
