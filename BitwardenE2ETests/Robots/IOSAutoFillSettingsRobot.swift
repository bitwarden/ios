import XCTest

// MARK: - IOSAutoFillSettingsRobot

/// Settings > General > AutoFill & Passwords.
///
final class IOSAutoFillSettingsRobot: Robot {
    // MARK: Properties

    private static let bitwardenToggleIdentifier = "AutoFillFromBitwardenToggle"

    private var applePasswordsToggle: XCUIElement {
        app.switches.matching(identifier: "AutoFillFromPasswordsToggle").firstMatch
    }

    private var bitwardenToggle: XCUIElement {
        app.switches.matching(identifier: Self.bitwardenToggleIdentifier).firstMatch
    }

    // MARK: Methods

    /// Opens Settings on the AutoFill & Passwords screen.
    ///
    static func open(file: StaticString = #filePath, line: UInt = #line) -> IOSAutoFillSettingsRobot {
        let settings = SystemApps.relaunchSettings()
        let general = settings.cells.staticTexts["General"]
        XCTAssertTrue(
            general.waitForExistence(timeout: E2ETimeouts.screen),
            "Settings: General not found",
            file: file,
            line: line,
        )
        general.tap()
        let autofill = settings.staticTexts["AutoFill & Passwords"]
        if !autofill.waitForExistence(timeout: E2ETimeouts.element) {
            settings.swipeUp()
        }
        XCTAssertTrue(
            autofill.existsOrAppears(within: E2ETimeouts.element),
            "Settings: AutoFill & Passwords not found",
            file: file,
            line: line,
        )
        autofill.tap()
        return IOSAutoFillSettingsRobot(
            app: settings,
            anchor: settings.switches.matching(identifier: bitwardenToggleIdentifier).firstMatch,
            file: file,
            line: line,
        )
    }

    /// Makes Bitwarden the only AutoFill provider: Apple Passwords off, Bitwarden on. With a single
    /// provider the keyboard's Passwords key opens it directly, without asking which one to use.
    ///
    /// Log in first: turning Bitwarden on starts the AutoFill extension, and a Debug build of it
    /// crashes when there is no account.
    ///
    /// Both settings outlive the test. Apple Passwords stays off on the simulator until it's turned
    /// back on in Settings.
    ///
    @discardableResult
    func useBitwardenAsOnlyProvider(file: StaticString = #filePath, line: UInt = #line) -> Self {
        if isOn(applePasswordsToggle) {
            flip(applePasswordsToggle)
        }
        if !isOn(bitwardenToggle) {
            flip(bitwardenToggle)
            // Turning Bitwarden on opens its setup screen over Settings. The provider is on without it.
            tap(app.buttons["CancelButton"], file: file, line: line)
        }
        assertValue("0", of: applePasswordsToggle, "Apple Passwords is still on", file: file, line: line)
        assertValue("1", of: bitwardenToggle, "Bitwarden isn't on", file: file, line: line)
        return self
    }

    // MARK: Private

    /// Waits until a switch reports the given value.
    ///
    private func assertValue(
        _ value: String,
        of toggle: XCUIElement,
        _ message: String,
        file: StaticString,
        line: UInt,
    ) {
        XCTAssertTrue(
            toggle.hasOrGetsValue(value, within: E2ETimeouts.element),
            "Settings: \(message)",
            file: file,
            line: line,
        )
    }

    /// Flips a provider switch. The row-sized switch doesn't toggle when tapped at its center; its
    /// inner switch does.
    ///
    private func flip(_ toggle: XCUIElement) {
        tap(toggle.switches.firstMatch)
    }

    private func isOn(_ toggle: XCUIElement) -> Bool {
        (toggle.value as? String) == "1"
    }
}
