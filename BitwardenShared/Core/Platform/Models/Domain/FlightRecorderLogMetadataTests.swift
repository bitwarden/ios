import XCTest

@testable import BitwardenShared

class FlightRecorderLogMetadataTests: BitwardenTestCase {
    // MARK: Properties

    let logOneHour = FlightRecorderLogMetadata.fixture(
        duration: .oneHour,
        startDate: Date(year: 2025, month: 4, day: 3, hour: 10, minute: 30)
    )

    let logEightHours = FlightRecorderLogMetadata.fixture(
        duration: .eightHours,
        startDate: Date(year: 2025, month: 4, day: 3, hour: 10, minute: 30)
    )

    // MARK: Tests

    /// `endDate` returns the date when logging will or did end for the log.
    func test_endData() {
        XCTAssertEqual(logOneHour.endDate, Date(year: 2025, month: 4, day: 3, hour: 11, minute: 30))
        XCTAssertEqual(logEightHours.endDate, Date(year: 2025, month: 4, day: 3, hour: 18, minute: 30))
    }

    /// `formattedLoggingDateRange` returns the formatted date range for when the flight recorder was enabled.
    func test_formattedLoggingDateRange() {
        XCTAssertEqual(
            logOneHour.formattedLoggingDateRange,
            "2025-04-03T10:30:00 - 2025-04-03T11:30:00"
        )
        XCTAssertEqual(
            logEightHours.formattedLoggingDateRange,
            "2025-04-03T10:30:00 - 2025-04-03T18:30:00"
        )
    }

    /// `formattedExpiration(currentDate:)` returns the formatted date for when the log expires
    /// when the log expires for a while from now.
    func test_formattedExpiration_long() {
        var currentDate = Date(year: 2025, month: 4, day: 3, hour: 8)
        XCTAssertEqual(
            logOneHour.formattedExpiration(currentDate: currentDate),
            Localizations.expiresInXDays(30)
        )
        XCTAssertEqual(
            logEightHours.formattedExpiration(currentDate: currentDate),
            Localizations.expiresInXDays(30)
        )
    }

    /// `formattedExpiration(currentDate:)` returns the formatted date for when the log expires
    /// when the log expires within a few days.
    func test_formattedExpiration_short() {
        var currentDate = Date(year: 2025, month: 5, day: 1, hour: 8)
        XCTAssertEqual(
            logOneHour.formattedExpiration(currentDate: currentDate),
            Localizations.expiresInXDays(2)
        )
        XCTAssertEqual(
            logEightHours.formattedExpiration(currentDate: currentDate),
            Localizations.expiresInXDays(2)
        )
    }

    /// `formattedExpiration(currentDate:)` returns the formatted date for when the log expires
    /// when the log expires today.
    func test_formattedExpiration_today() {
        var currentDate = Date(year: 2025, month: 5, day: 3, hour: 8)
        XCTAssertEqual(
            logOneHour.formattedExpiration(currentDate: currentDate),
            Localizations.expiresToday
        )
        XCTAssertEqual(
            logEightHours.formattedExpiration(currentDate: currentDate),
            Localizations.expiresToday
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
