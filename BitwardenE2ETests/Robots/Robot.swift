import XCTest

// MARK: - Robot

/// A screen-scoped set of actions and assertions.
///
@MainActor
class Robot {
    // MARK: Properties

    /// The application under test.
    let app: XCUIApplication

    // MARK: Initialization

    /// Creates the robot once its screen is shown.
    ///
    /// - Parameters:
    ///   - app: The application under test.
    ///   - anchor: An element that exists only on this screen.
    ///   - timeout: How long to wait for the anchor.
    ///   - file: The file to attribute a failure to.
    ///   - line: The line to attribute a failure to.
    ///
    init(
        app: XCUIApplication,
        anchor: XCUIElement,
        timeout: TimeInterval = E2ETimeouts.screen,
        file: StaticString = #filePath,
        line: UInt = #line,
    ) {
        self.app = app
        XCTAssertTrue(
            anchor.existsOrAppears(within: timeout),
            "\(Self.self): screen never appeared (anchor \(anchor))",
            file: file,
            line: line,
        )
    }

    // MARK: Methods

    /// Waits for an element, then taps it.
    ///
    func tap(_ element: XCUIElement, file: StaticString = #filePath, line: UInt = #line) {
        waitToActOn(element, file: file, line: line)
        element.tap()
    }

    /// Waits for an element, then returns its label.
    ///
    func text(of element: XCUIElement, file: StaticString = #filePath, line: UInt = #line) -> String {
        waitFor(element, file: file, line: line)
        return element.label
    }

    /// Waits for a field, focuses it, then types into it.
    ///
    func type(_ text: String, into element: XCUIElement, file: StaticString = #filePath, line: UInt = #line) {
        waitToActOn(element, file: file, line: line)
        element.tap()
        element.typeText(text)
    }

    /// Waits for an element that is about to be tapped or typed into. XCUITest's wait first checks
    /// about a second after the call, and actions depend on that pause: a tap sent the moment a
    /// control appears, or right after typing, is sometimes dropped.
    ///
    func waitToActOn(_ element: XCUIElement, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(
            element.waitForExistence(timeout: E2ETimeouts.element),
            "\(Self.self): \(element) not found",
            file: file,
            line: line,
        )
    }

    /// Fails with the robot and element names if the element doesn't appear. For assertions; use
    /// `tap` or `type` to act on the element.
    ///
    func waitFor(_ element: XCUIElement, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(
            element.existsOrAppears(within: E2ETimeouts.element),
            "\(Self.self): \(element) not found",
            file: file,
            line: line,
        )
    }
}
