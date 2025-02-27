import Foundation
import XCTest

@testable import AuthenticatorShared

// MARK: - UITests

@MainActor
class UITests: AuthenticatorTestCase {
    // MARK: Tests

    func test_duration_animated() {
        UI.animated = true
        let duration = UI.duration(3)
        XCTAssertEqual(duration, 3)
    }

    func test_duration_notAnimated() {
        UI.animated = false
        let duration = UI.duration(3)
        XCTAssertEqual(duration, 0)
    }

    func test_after_animated() {
        UI.animated = true
        let after = UI.after(3)
        let duration = (DispatchTime.now() + 3).distance(to: after).totalSeconds
        XCTAssertEqual(duration, 0, accuracy: 0.1)
    }

    func test_after_notAnimated() {
        UI.animated = false
        let after = UI.after(3)
        let duration = DispatchTime.now().distance(to: after).totalSeconds
        XCTAssertEqual(duration, 0, accuracy: 0.1)
    }
}
