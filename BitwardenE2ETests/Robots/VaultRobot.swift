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

    /// Fails if an alert covers the vault. The only alerts expected here are the notification
    /// prompts, which appear when the simulator wasn't prepared.
    ///
    @discardableResult
    func assertNoAlertIsShown(file: StaticString = #filePath, line: UInt = #line) -> Self {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        XCTAssertFalse(
            app.alerts.firstMatch.exists || springboard.alerts.firstMatch.exists,
            """
            \(Self.self): an alert is shown over the vault. If it asks about notifications, grant the \
            permission with `Scripts/run-e2e-tests.sh --prepare-simulator`.
            """,
            file: file,
            line: line,
        )
        return self
    }

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
