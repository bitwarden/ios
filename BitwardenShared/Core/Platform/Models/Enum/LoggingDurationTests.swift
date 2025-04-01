import XCTest

@testable import BitwardenShared

class LoggingDurationTests: BitwardenTestCase {
    // MARK: Tests

    /// `localizedName` returns the correct values.
    func test_localizedName() {
        XCTAssertEqual(LoggingDuration.oneHour.localizedName, Localizations.oneHour)
        XCTAssertEqual(LoggingDuration.eightHours.localizedName, Localizations.xHours(8))
        XCTAssertEqual(LoggingDuration.twentyFourHours.localizedName, Localizations.xHours(24))
        XCTAssertEqual(LoggingDuration.oneWeek.localizedName, Localizations.oneWeek)
    }
}
