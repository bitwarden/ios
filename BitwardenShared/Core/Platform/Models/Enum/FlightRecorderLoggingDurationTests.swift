import XCTest

@testable import BitwardenShared

class FlightRecorderLoggingDurationTests: BitwardenTestCase {
    // MARK: Tests

    /// `localizedName` returns the correct values.
    func test_localizedName() {
        XCTAssertEqual(FlightRecorderLoggingDuration.oneHour.localizedName, Localizations.oneHour)
        XCTAssertEqual(FlightRecorderLoggingDuration.eightHours.localizedName, Localizations.xHours(8))
        XCTAssertEqual(FlightRecorderLoggingDuration.twentyFourHours.localizedName, Localizations.xHours(24))
        XCTAssertEqual(FlightRecorderLoggingDuration.oneWeek.localizedName, Localizations.oneWeek)
    }
}
