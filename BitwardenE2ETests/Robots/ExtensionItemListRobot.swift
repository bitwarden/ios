import XCTest

// MARK: - ExtensionItemListRobot

/// The AutoFill extension's item list.
///
final class ExtensionItemListRobot: Robot {
    // MARK: Initialization

    /// Creates the robot once the list is shown.
    ///
    /// - Parameter app: The app hosting the extension: the requesting app for password AutoFill,
    ///   SpringBoard for passkeys.
    ///
    init(app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        super.init(app: app, anchor: app.buttons["AddItemFloatingActionButton"], file: file, line: line)
    }

    // MARK: Methods

    /// Saves the passkey being registered as a new login item.
    ///
    func savePasskeyAsNewLogin(file: StaticString = #filePath, line: UInt = #line) {
        tap(app.buttons["Save passkey as new login"], file: file, line: line)
    }

    /// Selects the item with the given name.
    ///
    func selectItem(named name: String, file: StaticString = #filePath, line: UInt = #line) {
        tap(app.cipherCell(named: name), file: file, line: line)
    }

    /// Selects the passkey saved for the given relying party username.
    ///
    func selectPasskey(forUsername username: String, file: StaticString = #filePath, line: UInt = #line) {
        tap(app.cipherCell(subtitled: username), file: file, line: line)
    }
}
