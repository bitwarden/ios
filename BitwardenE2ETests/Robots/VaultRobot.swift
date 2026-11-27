import XCTest

// MARK: - VaultRobot

/// The vault list, the first screen after logging in.
///
final class VaultRobot: Robot {
    // MARK: Initialization

    /// Creates the robot once the vault is shown.
    ///
    /// - Parameters:
    ///   - app: The application under test.
    ///   - timeout: How long to wait for the vault. Pass `E2ETimeouts.login` right after logging in.
    ///   - file: The file to attribute a failure to.
    ///   - line: The line to attribute a failure to.
    ///
    init(
        app: XCUIApplication,
        timeout: TimeInterval = E2ETimeouts.screen,
        file: StaticString = #filePath,
        line: UInt = #line,
    ) {
        super.init(app: app, anchor: app.tabBars.firstMatch, timeout: timeout, file: file, line: line)
    }

    // MARK: Methods

    /// Asserts the vault list shows the item with the given name.
    ///
    @discardableResult
    func assertShowsItem(named name: String, file: StaticString = #filePath, line: UInt = #line) -> Self {
        waitFor(app.cipherCell(named: name), file: file, line: line)
        return self
    }

    /// Opens the item with the given name.
    ///
    func openItem(named name: String) {
        tap(app.cipherCell(named: name))
    }
}
