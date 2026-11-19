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

    /// Opens the item with the given name.
    ///
    func openItem(named name: String) {
        let cell = app.buttons
            .matching(identifier: "CipherCell")
            .containing(NSPredicate(format: "identifier == %@ AND label == %@", "CipherNameLabel", name))
            .firstMatch
        tap(cell)
    }
}
