import XCTest

/// Waits that check the current state first and then every `E2ETimeouts.pollInterval`. XCUITest's
/// own waits check once a second, the first time about a second after the call.
///
extension XCUIElement {
    /// Whether the element exists now or appears within the timeout.
    ///
    func existsOrAppears(within timeout: TimeInterval) -> Bool {
        poll(within: timeout) { exists }
    }

    /// Whether the element is gone now or disappears within the timeout.
    ///
    func isGoneOrDisappears(within timeout: TimeInterval) -> Bool {
        poll(within: timeout) { !exists }
    }

    /// Whether the element's value is `expected` now or becomes it within the timeout.
    ///
    func hasOrGetsValue(_ expected: String, within timeout: TimeInterval) -> Bool {
        poll(within: timeout) { exists && value as? String == expected }
    }

    private func poll(within timeout: TimeInterval, until condition: () -> Bool) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition() {
            guard Date() < deadline else { return false }
            RunLoop.current.run(until: Date().addingTimeInterval(E2ETimeouts.pollInterval))
        }
        return true
    }
}
