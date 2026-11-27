import XCTest

// MARK: - SystemApps

/// The system apps the tests drive besides the app under test. System UI and the AutoFill extension
/// are queried through the app that hosts them, or through SpringBoard.
///
enum SystemApps {
    /// Safari.
    static var safari: XCUIApplication { XCUIApplication(bundleIdentifier: "com.apple.mobilesafari") }

    /// The Settings app.
    static var settings: XCUIApplication { XCUIApplication(bundleIdentifier: "com.apple.Preferences") }

    /// SpringBoard, which draws the system passkey sheets.
    static var springboard: XCUIApplication { XCUIApplication(bundleIdentifier: "com.apple.springboard") }
}
