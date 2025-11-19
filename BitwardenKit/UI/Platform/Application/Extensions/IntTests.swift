import BitwardenKit
import Foundation
import XCTest

class IntTests: BitwardenTestCase {
    // MARK: Tests

    /// `numberOfDigits()` returns the number of digits within the value.
    func test_numberOfDigits() {
        XCTAssertEqual((-12345).numberOfDigits, 5)
        XCTAssertEqual((-1).numberOfDigits, 1)
        XCTAssertEqual(0.numberOfDigits, 1)
        XCTAssertEqual(1.numberOfDigits, 1)
        XCTAssertEqual(10.numberOfDigits, 2)
        XCTAssertEqual(999.numberOfDigits, 3)
        XCTAssertEqual(12345.numberOfDigits, 5)
    }

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
