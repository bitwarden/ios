import XCTest

// MARK: - SafariRobot

/// A web page in Safari. Each page has its own subclass.
///
class SafariRobot: Robot {
    // MARK: Methods

    /// Opens `url` in a freshly started Safari, which doesn't keep a stuck AutoFill UI from an
    /// earlier test. Safari has to be in Private Browsing (`switchToPrivateBrowsing`): the page
    /// then opens in a new private tab, without the data sites stored earlier, such as a
    /// remembered username.
    ///
    static func openSafari(at url: URL, file: StaticString = #filePath, line: UInt = #line) -> XCUIApplication {
        let safari = SystemApps.safari
        safari.terminate()
        // `XCUIApplication.open(_:)` would target Safari explicitly, but needs iOS 16.4; the target deploys lower.
        XCUIDevice.shared.system.open(url)
        XCTAssertTrue(
            safari.wait(for: .runningForeground, timeout: E2ETimeouts.screen),
            "Safari didn't open",
            file: file,
            line: line,
        )
        return safari
    }

    /// Switches Safari to Private Browsing by opening a private tab from the Tabs button's menu,
    /// which a long press shows. Safari stays in Private Browsing across restarts, so once per
    /// test class is enough.
    ///
    static func switchToPrivateBrowsing(file: StaticString = #filePath, line: UInt = #line) {
        let safari = SystemApps.relaunchSafari()
        let tabs = safari.buttons["TabOverviewButton"]
        XCTAssertTrue(
            tabs.waitForExistence(timeout: E2ETimeouts.screen),
            "Safari: the Tabs button not found",
            file: file,
            line: line,
        )
        tabs.press(forDuration: E2ETimeouts.longPress)
        let newPrivateTab = safari.buttons["New Private Tab"]
        XCTAssertTrue(
            newPrivateTab.waitForExistence(timeout: E2ETimeouts.element),
            "Safari: the tabs menu didn't open",
            file: file,
            line: line,
        )
        newPrivateTab.tap()
        XCTAssertTrue(
            newPrivateTab.isGoneOrDisappears(within: E2ETimeouts.element),
            "Safari: the tabs menu is still shown",
            file: file,
            line: line,
        )
    }

    /// Closes the keyboard with its Done button. iOS 27: a tap inside a minimized keyboard's frame
    /// re-expands the keyboard instead of reaching the page.
    ///
    func dismissKeyboard(file: StaticString = #filePath, line: UInt = #line) {
        tap(app.buttons["Done"], file: file, line: line)
        XCTAssertTrue(
            app.keyboards.firstMatch.isGoneOrDisappears(within: E2ETimeouts.element),
            "Safari: keyboard still shown",
            file: file,
            line: line,
        )
    }

    /// Types into a web field and checks the result. The field is empty: a private tab has no
    /// value from an earlier visit. It is tapped at its center because Safari draws an AutoFill
    /// button at the trailing edge of an empty credential field.
    ///
    func fill(_ field: XCUIElement, with text: String, file: StaticString = #filePath, line: UInt = #line) {
        tap(field, file: file, line: line)
        // iOS 27 drops typeText until the keyboard is up.
        waitToActOn(app.keyboards.keys.firstMatch, file: file, line: line)
        field.typeText(text)
        XCTAssertEqual(field.value as? String, text, "Safari: the field wasn't filled", file: file, line: line)
    }

    /// Focuses a field and requires the software keyboard, which carries the AutoFill bar.
    ///
    func focus(_ field: XCUIElement, file: StaticString = #filePath, line: UInt = #line) {
        tap(field, file: file, line: line)
        XCTAssertTrue(
            app.keyboards.keys.firstMatch.existsOrAppears(within: E2ETimeouts.element),
            "Safari: no software keyboard. Turn off I/O > Keyboard > Connect Hardware Keyboard in Simulator.",
            file: file,
            line: line,
        )
    }

    /// Taps a button of the page.
    ///
    func tapPageButton(_ label: String, file: StaticString = #filePath, line: UInt = #line) {
        tap(app.webViews.buttons[label], file: file, line: line)
    }

    /// Waits for a text of the page that matches the predicate format.
    ///
    func waitForPageText(_ format: String, _ argument: String, file: StaticString = #filePath, line: UInt = #line) {
        waitFor(
            app.webViews.staticTexts.matching(NSPredicate(format: format, argument)).firstMatch,
            file: file,
            line: line,
        )
    }
}
