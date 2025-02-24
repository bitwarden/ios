import XCTest

@testable import AuthenticatorShared

final class SessionTimeoutValueTests: AuthenticatorTestCase {
    // MARK: Tests

    /// `allCases` returns all of the cases in the correct order.
    func test_allCases() {
        XCTAssertEqual(
            SessionTimeoutValue.allCases,
            [
                .immediately,
                .oneMinute,
                .fiveMinutes,
                .fifteenMinutes,
                .thirtyMinutes,
                .oneHour,
                .fourHours,
                .onAppRestart,
                .never,
            ]
        )
    }

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

    /// `localizedName` returns the correct values.
    func test_localizedName() {
        XCTAssertEqual(SessionTimeoutValue.immediately.localizedName, Localizations.immediately)
        XCTAssertEqual(SessionTimeoutValue.oneMinute.localizedName, Localizations.oneMinute)
        XCTAssertEqual(SessionTimeoutValue.fiveMinutes.localizedName, Localizations.fiveMinutes)
        XCTAssertEqual(SessionTimeoutValue.fifteenMinutes.localizedName, Localizations.fifteenMinutes)
        XCTAssertEqual(SessionTimeoutValue.thirtyMinutes.localizedName, Localizations.thirtyMinutes)
        XCTAssertEqual(SessionTimeoutValue.oneHour.localizedName, Localizations.oneHour)
        XCTAssertEqual(SessionTimeoutValue.fourHours.localizedName, Localizations.fourHours)
        XCTAssertEqual(SessionTimeoutValue.onAppRestart.localizedName, Localizations.onRestart)
        XCTAssertEqual(SessionTimeoutValue.never.localizedName, Localizations.never)
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
