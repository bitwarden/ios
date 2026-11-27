import XCTest

// MARK: - PasskeySheetRobot

/// The system passkey sheet. It is drawn by SpringBoard, not by the requesting app.
///
final class PasskeySheetRobot: Robot {
    // MARK: Properties

    private var continueButton: XCUIElement {
        app.otherElements["ASAuthorizationControllerContinueButton"].buttons.firstMatch
    }

    // MARK: Initialization

    /// Creates the robot once the sheet is shown.
    ///
    init(file: StaticString = #filePath, line: UInt = #line) {
        let springboard = SystemApps.springboard
        super.init(
            app: springboard,
            anchor: springboard.otherElements["ASAuthorizationControllerContinueButton"],
            file: file,
            line: line,
        )
    }

    // MARK: Methods

    /// Asserts the sheet has closed. While it is closing, a page can't start another passkey
    /// request: the request is dropped and no sheet opens.
    ///
    func assertClosed(file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(
            app.otherElements["ASAuthorizationControllerContinueButton"].isGoneOrDisappears(within: E2ETimeouts.screen),
            "\(Self.self): still shown",
            file: file,
            line: line,
        )
    }

    /// Confirms the sheet ("Add Passkey" or "Continue").
    ///
    @discardableResult
    func confirm(file: StaticString = #filePath, line: UInt = #line) -> Self {
        tap(continueButton, file: file, line: line)
        return self
    }

    /// Picks Bitwarden's own list instead of a passkey offered on the sheet.
    ///
    /// iOS simulators don't offer a passkey Bitwarden saved moments ago, so signing in right after
    /// registering has to go through this option. If iOS starts offering the passkey, the option
    /// is no longer shown and this step fails.
    ///
    func chooseMoreFromBitwarden(file: StaticString = #filePath, line: UInt = #line) -> Self {
        // Matched by prefix: the label ends in a Unicode ellipsis.
        let moreFromBitwarden = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'More from Bitwarden'"))
        tap(moreFromBitwarden.element, file: file, line: line)
        return self
    }
}
