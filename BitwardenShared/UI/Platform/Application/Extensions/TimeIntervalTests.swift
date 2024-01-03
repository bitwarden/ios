import Foundation
import XCTest

@testable import BitwardenShared

class TimeIntervalTests: BitwardenTestCase {
    // MARK: Tests

    /// `.timeInHoursMinutes()` formats the time interval correctly.
    func test_hours() {
        let string = TimeInterval(3600).timeInHoursMinutes()
        XCTAssertEqual(string, "01:00")
    }

    /// `.timeInHoursMinutes()` formats the time interval correctly.
    func test_hours_minutes() {
        let string = TimeInterval(3660).timeInHoursMinutes()
        XCTAssertEqual(string, "01:01")
    }

    /// `.timeInHoursMinutes()` formats the time interval correctly.
    func test_minutes() {
        let string = TimeInterval(60).timeInHoursMinutes()
        XCTAssertEqual(string, "00:01")
    }
}
