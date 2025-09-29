import XCTest

import BitwardenResources
@testable import BitwardenShared

class FlightRecorderLoggingDurationTests: BitwardenTestCase {
    // MARK: Tests

    /// `Calendar.date(byAdding:to:)` adds the logging duration to the specified date.
    func test_calendarDateByAdding() {
        let date = Date(year: 2025, month: 3, day: 4, hour: 8, minute: 30, second: 20)

        let oneHour = Calendar.current.date(byAdding: .oneHour, to: date)
        XCTAssertEqual(oneHour, Date(year: 2025, month: 3, day: 4, hour: 9, minute: 30, second: 20))

        let eightHours = Calendar.current.date(byAdding: .eightHours, to: date)
        XCTAssertEqual(eightHours, Date(year: 2025, month: 3, day: 4, hour: 16, minute: 30, second: 20))

        let twentyFourHours = Calendar.current.date(byAdding: .twentyFourHours, to: date)
        XCTAssertEqual(twentyFourHours, Date(year: 2025, month: 3, day: 5, hour: 8, minute: 30, second: 20))

        let oneWeek = Calendar.current.date(byAdding: .oneWeek, to: date)
        XCTAssertEqual(oneWeek, Date(year: 2025, month: 3, day: 11, hour: 8, minute: 30, second: 20))
    }

    /// `localizedName` returns the correct values.
    func test_localizedName() {
        XCTAssertEqual(FlightRecorderLoggingDuration.oneHour.localizedName, Localizations.oneHour)
        XCTAssertEqual(FlightRecorderLoggingDuration.eightHours.localizedName, Localizations.xHours(8))
        XCTAssertEqual(FlightRecorderLoggingDuration.twentyFourHours.localizedName, Localizations.xHours(24))
        XCTAssertEqual(FlightRecorderLoggingDuration.oneWeek.localizedName, Localizations.oneWeek)
    }

    /// `shortDescription` returns a short string representation of the logging duration.
    func test_shortDescription() {
        XCTAssertEqual(FlightRecorderLoggingDuration.oneHour.shortDescription, "1h")
        XCTAssertEqual(FlightRecorderLoggingDuration.eightHours.shortDescription, "8h")
        XCTAssertEqual(FlightRecorderLoggingDuration.twentyFourHours.shortDescription, "24h")
        XCTAssertEqual(FlightRecorderLoggingDuration.oneWeek.shortDescription, "1w")
    }
}
