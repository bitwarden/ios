import XCTest

// MARK: - AutoFillKeyboardRobot

/// The keyboard's AutoFill bar while a credential field is focused.
///
final class AutoFillKeyboardRobot: Robot {
    // MARK: Initialization

    /// Creates the robot once the bar shows its Passwords key.
    ///
    /// - Parameter app: The app whose field is focused.
    ///
    init(app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        super.init(app: app, anchor: app.buttons["Passwords"], timeout: E2ETimeouts.element, file: file, line: line)
    }

    // MARK: Methods

    /// Opens the AutoFill provider. Bitwarden has to be the only one turned on
    /// (`IOSAutoFillSettingsRobot.useBitwardenAsOnlyProvider`); with a second provider iOS asks
    /// which one to use and the next screen never appears.
    ///
    func openProvider(file: StaticString = #filePath, line: UInt = #line) {
        tap(app.buttons["Passwords"], file: file, line: line)
    }
}
