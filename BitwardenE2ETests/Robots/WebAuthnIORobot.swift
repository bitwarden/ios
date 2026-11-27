import XCTest

// MARK: - WebAuthnIORobot

/// webauthn.io, a public relying party for registering and using passkeys. test-the-web has no
/// passkey page, so this is the suite's one third-party site. It has no way to delete a
/// registration, so every run leaves one username behind there.
///
final class WebAuthnIORobot: SafariRobot {
    // MARK: Methods

    /// Opens the site in Safari.
    ///
    static func open(file: StaticString = #filePath, line: UInt = #line) -> WebAuthnIORobot {
        let url = URL(string: "https://webauthn.io")!
        let safari = openSafari(at: url, file: file, line: line)
        return WebAuthnIORobot(app: safari, anchor: safari.webViews.buttons["Register"], file: file, line: line)
    }

    /// Asserts the site reports the passkey as registered.
    ///
    @discardableResult
    func assertRegistered(file: StaticString = #filePath, line: UInt = #line) -> Self {
        waitForPageText("label BEGINSWITH %@", "Success", file: file, line: line)
        return self
    }

    /// Asserts the site reports the user as signed in.
    ///
    @discardableResult
    func assertSignedIn(file: StaticString = #filePath, line: UInt = #line) -> Self {
        waitForPageText("label CONTAINS[c] %@", "logged in", file: file, line: line)
        return self
    }

    /// Starts signing in with a passkey, which brings up the system passkey sheet.
    ///
    func authenticate(file: StaticString = #filePath, line: UInt = #line) {
        tapPageButton("Authenticate", file: file, line: line)
    }

    /// Enters the username the passkey is registered for, then closes the keyboard, which covers
    /// the page's buttons.
    ///
    @discardableResult
    func enterUsername(_ username: String, file: StaticString = #filePath, line: UInt = #line) -> Self {
        fill(app.webViews.textFields.firstMatch, with: username, file: file, line: line)
        dismissKeyboard(file: file, line: line)
        return self
    }

    /// Starts registering a passkey, which brings up the system passkey sheet.
    ///
    func register(file: StaticString = #filePath, line: UInt = #line) {
        tapPageButton("Register", file: file, line: line)
    }
}
