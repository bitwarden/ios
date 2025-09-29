import XCTest

import BitwardenResources
@testable import BitwardenShared

class FlightRecorderLogMetadataTests: BitwardenTestCase {
    // MARK: Properties

    let logOneHour = FlightRecorderLogMetadata.fixture(
        duration: .oneHour,
        endDate: Date(year: 2025, month: 4, day: 3, hour: 11, minute: 30),
        expirationDate: Date(year: 2025, month: 5, day: 3, hour: 11, minute: 30),
        startDate: Date(year: 2025, month: 4, day: 3, hour: 10, minute: 30)
    )

    let logEightHours = FlightRecorderLogMetadata.fixture(
        duration: .eightHours,
        endDate: Date(year: 2025, month: 4, day: 3, hour: 18, minute: 30),
        expirationDate: Date(year: 2025, month: 5, day: 3, hour: 18, minute: 30),
        startDate: Date(year: 2025, month: 4, day: 3, hour: 10, minute: 30)
    )

    // MARK: Tests

    /// `formattedLoggingDateRange` returns the formatted date range for when the flight recorder was enabled.
    func test_formattedLoggingDateRange() {
        XCTAssertEqual(
            logOneHour.formattedLoggingDateRange,
            "2025-04-03T10:30:00 – 2025-04-03T11:30:00"
        )
        XCTAssertEqual(
            logEightHours.formattedLoggingDateRange,
            "2025-04-03T10:30:00 – 2025-04-03T18:30:00"
        )
    }

    /// `formattedExpiration(currentDate:)` returns `nil` if the log is still active.
    func test_formattedExpiration_activeLog() {
        let currentDate = Date(year: 2025, month: 4, day: 3, hour: 10, minute: 30)
        let log = FlightRecorderLogMetadata.fixture(
            duration: .oneHour,
            isActiveLog: true,
            startDate: currentDate
        )
        XCTAssertNil(log.formattedExpiration(currentDate: currentDate))
    }

    /// `formattedExpiration(currentDate:)` returns the formatted date for when the log expires
    /// more than two days from today.
    func test_formattedExpiration_greaterThanTwoDays() {
        let currentDate = Date(year: 2025, month: 4, day: 30, hour: 8)
        XCTAssertEqual(
            logOneHour.formattedExpiration(currentDate: currentDate),
            Localizations.expiresOnXDate("5/3/25")
        )
        XCTAssertEqual(
            logEightHours.formattedExpiration(currentDate: currentDate),
            Localizations.expiresOnXDate("5/3/25")
        )
    }

    /// `formattedExpiration(currentDate:)` returns the formatted date for when the log expires today.
    func test_formattedExpiration_today() {
        let currentDate = Date(year: 2025, month: 5, day: 3, hour: 8)
        XCTAssertEqual(
            logOneHour.formattedExpiration(currentDate: currentDate),
            Localizations.expiresAtXTime("11:30 AM")
        )
        XCTAssertEqual(
            logEightHours.formattedExpiration(currentDate: currentDate),
            Localizations.expiresAtXTime("6:30 PM")
        )
    }

    /// `formattedExpiration(currentDate:)` returns the formatted date for when the log expires tomorrow.
    func test_formattedExpiration_tomorrow() {
        let currentDate = Date(year: 2025, month: 5, day: 2, hour: 8)
        XCTAssertEqual(
            logOneHour.formattedExpiration(currentDate: currentDate),
            Localizations.expiresTomorrow
        )
        XCTAssertEqual(
            logEightHours.formattedExpiration(currentDate: currentDate),
            Localizations.expiresTomorrow
        )
    }

    /// `loggingDateRangeAccessibilityLabel` returns the accessibility label for the logging date range.
    func test_loggingDateRangeAccessibilityLabel() {
        XCTAssertEqual(
            logOneHour.loggingDateRangeAccessibilityLabel,
            "Apr 3, 2025 at 10:30 AM to Apr 3, 2025 at 11:30 AM"
        )
        XCTAssertEqual(
            logEightHours.loggingDateRangeAccessibilityLabel,
            "Apr 3, 2025 at 10:30 AM to Apr 3, 2025 at 6:30 PM"
        )
    }
}
