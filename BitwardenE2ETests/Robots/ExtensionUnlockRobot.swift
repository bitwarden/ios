import XCTest

// MARK: - ExtensionUnlockRobot

/// The AutoFill extension's master password screen.
///
final class ExtensionUnlockRobot: Robot {
    // MARK: Initialization

    /// Creates the robot once the screen is shown.
    ///
    /// - Parameter app: The app hosting the extension: the requesting app for password AutoFill,
    ///   SpringBoard for passkeys.
    ///
    init(app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        super.init(app: app, anchor: app.secureTextFields["MasterPasswordEntry"], file: file, line: line)
    }

    // MARK: Methods

    /// Types the master password and unlocks.
    ///
    func unlock(with password: String, file: StaticString = #filePath, line: UInt = #line) {
        type(password, into: app.secureTextFields["MasterPasswordEntry"], file: file, line: line)
        tap(app.buttons["UnlockVaultButton"], file: file, line: line)
    }
}
