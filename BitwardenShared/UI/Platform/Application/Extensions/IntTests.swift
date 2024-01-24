import Foundation
import XCTest

@testable import BitwardenShared

class IntTests: BitwardenTestCase {
    // MARK: Tests

    /// `.timeInHoursMinutes()` formats the time interval correctly.
    func test_hours() {
        let string = 3600.timeInHoursMinutes()
        XCTAssertEqual(string, "01:00")
    }

    /// `.timeInHoursMinutes()` formats the time interval correctly.
    func test_hours_minutes() {
        let string = 3660.timeInHoursMinutes()
        XCTAssertEqual(string, "01:01")
    }

    /// `.timeInHoursMinutes()` formats the time interval correctly.
    func test_minutes() {
        let string = 60.timeInHoursMinutes()
        XCTAssertEqual(string, "00:01")
    }
}
