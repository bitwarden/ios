import BitwardenKit
import XCTest

final class SessionTimeoutValueTests: BitwardenTestCase {
    // MARK: Tests

    /// `init` returns the correct case for the given raw value.
    func test_initFromRawValue() {
        XCTAssertEqual(SessionTimeoutValue.immediately, SessionTimeoutValue(rawValue: 0))
        XCTAssertEqual(SessionTimeoutValue.oneMinute, SessionTimeoutValue(rawValue: 1))
        XCTAssertEqual(SessionTimeoutValue.fiveMinutes, SessionTimeoutValue(rawValue: 5))
        XCTAssertEqual(SessionTimeoutValue.fifteenMinutes, SessionTimeoutValue(rawValue: 15))
        XCTAssertEqual(SessionTimeoutValue.thirtyMinutes, SessionTimeoutValue(rawValue: 30))
        XCTAssertEqual(SessionTimeoutValue.oneHour, SessionTimeoutValue(rawValue: 60))
        XCTAssertEqual(SessionTimeoutValue.fourHours, SessionTimeoutValue(rawValue: 240))
        XCTAssertEqual(SessionTimeoutValue.onAppRestart, SessionTimeoutValue(rawValue: -1))
        XCTAssertEqual(SessionTimeoutValue.never, SessionTimeoutValue(rawValue: -2))
        XCTAssertEqual(SessionTimeoutValue.never, SessionTimeoutValue(rawValue: 12345))
    }

    /// `rawValue` returns the correct values.
    func test_rawValues() {
        XCTAssertEqual(SessionTimeoutValue.immediately.rawValue, 0)
        XCTAssertEqual(SessionTimeoutValue.oneMinute.rawValue, 1)
        XCTAssertEqual(SessionTimeoutValue.fiveMinutes.rawValue, 5)
        XCTAssertEqual(SessionTimeoutValue.fifteenMinutes.rawValue, 15)
        XCTAssertEqual(SessionTimeoutValue.thirtyMinutes.rawValue, 30)
        XCTAssertEqual(SessionTimeoutValue.oneHour.rawValue, 60)
        XCTAssertEqual(SessionTimeoutValue.fourHours.rawValue, 240)
        XCTAssertEqual(SessionTimeoutValue.onAppRestart.rawValue, -1)
        XCTAssertEqual(SessionTimeoutValue.never.rawValue, -2)
    }
}
