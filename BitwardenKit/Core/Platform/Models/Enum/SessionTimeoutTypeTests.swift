import BitwardenKit
import XCTest

final class SessionTimeoutTypeTests: BitwardenTestCase {
    // MARK: Tests

    /// `init(rawValue:)` returns the correct case for the given raw value string.
    func test_initFromRawValue() {
        XCTAssertEqual(SessionTimeoutType.immediately, SessionTimeoutType(rawValue: "immediately"))
        XCTAssertEqual(SessionTimeoutType.onAppRestart, SessionTimeoutType(rawValue: "onAppRestart"))
        // `onSystemLock` value maps to `onAppRestart` on mobile.
        XCTAssertEqual(SessionTimeoutType.onAppRestart, SessionTimeoutType(rawValue: "onSystemLock"))
        XCTAssertEqual(SessionTimeoutType.never, SessionTimeoutType(rawValue: "never"))
        XCTAssertEqual(SessionTimeoutType.custom, SessionTimeoutType(rawValue: "custom"))
        // `nil` value maps to `custom` on mobile in support to legacy.
        XCTAssertEqual(SessionTimeoutType.custom, SessionTimeoutType(rawValue: nil))
    }

    /// `init(value:)` returns the correct case for the given `SessionTimeoutValue`.
    func test_initFromSessionTimeoutValue() {
        XCTAssertEqual(SessionTimeoutType.immediately, SessionTimeoutType(value: .immediately))
        XCTAssertEqual(SessionTimeoutType.onAppRestart, SessionTimeoutType(value: .onAppRestart))
        XCTAssertEqual(SessionTimeoutType.never, SessionTimeoutType(value: .never))
        XCTAssertEqual(SessionTimeoutType.custom, SessionTimeoutType(value: .custom(123)))
    }

    /// `init(value:)` returns `.custom` for all predefined timeout values.
    func test_initFromSessionTimeoutValue_predefined() {
        XCTAssertEqual(SessionTimeoutType.custom, SessionTimeoutType(value: .oneMinute))
        XCTAssertEqual(SessionTimeoutType.custom, SessionTimeoutType(value: .fiveMinutes))
        XCTAssertEqual(SessionTimeoutType.custom, SessionTimeoutType(value: .fifteenMinutes))
        XCTAssertEqual(SessionTimeoutType.custom, SessionTimeoutType(value: .thirtyMinutes))
        XCTAssertEqual(SessionTimeoutType.custom, SessionTimeoutType(value: .oneHour))
        XCTAssertEqual(SessionTimeoutType.custom, SessionTimeoutType(value: .fourHours))
    }

    /// `rawValue` returns the correct string values.
    func test_rawValues() {
        XCTAssertEqual(SessionTimeoutType.immediately.rawValue, "immediately")
        XCTAssertEqual(SessionTimeoutType.onAppRestart.rawValue, "onAppRestart")
        XCTAssertEqual(SessionTimeoutType.never.rawValue, "never")
        XCTAssertEqual(SessionTimeoutType.custom.rawValue, "custom")
    }

    /// `timeoutType` returns the correct string representation values.
    func test_timeoutType() {
        XCTAssertEqual(SessionTimeoutType.immediately.timeoutType, "immediately")
        XCTAssertEqual(SessionTimeoutType.onAppRestart.timeoutType, "on app restart")
        XCTAssertEqual(SessionTimeoutType.never.timeoutType, "never")
        XCTAssertEqual(SessionTimeoutType.custom.timeoutType, "custom")
    }
}
