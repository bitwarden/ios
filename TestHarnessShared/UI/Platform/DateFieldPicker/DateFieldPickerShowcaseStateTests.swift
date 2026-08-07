import BitwardenKit
import XCTest

@testable import TestHarnessShared

// MARK: - DateFieldPickerShowcaseStateTests

/// Tests for `DateFieldPickerShowcaseState`.
///
class DateFieldPickerShowcaseStateTests: XCTestCase {
    // MARK: Tests

    /// `selectedDateDisplay` is an empty string when no date has been selected.
    func test_selectedDateDisplay_isEmptyWhenUnset() {
        let subject = DateFieldPickerShowcaseState()
        XCTAssertEqual(subject.selectedDateDisplay, "")
    }

    /// `selectedDateDisplay` shows the same calendar day that was selected, even when the stored
    /// UTC-anchored date falls on the previous day in the device's local time zone. This guards
    /// against a regression where the showcase read the stored date back with an implicit local
    /// time zone and displayed the day before the one the user picked.
    func test_selectedDateDisplay_matchesSelectedDayRegardlessOfDeviceTimeZone() {
        let losAngeles = TimeZone(identifier: "America/Los_Angeles")!
        let selectedLocalDay = Date(year: 2026, month: 8, day: 7, timeZone: losAngeles)
        let storedDate = selectedLocalDay.asUTCCalendarDay(from: losAngeles)

        var subject = DateFieldPickerShowcaseState()
        subject.selectedDate = storedDate

        XCTAssertEqual(subject.selectedDateDisplay, storedDate.longCalendarDateDisplay)
        XCTAssertTrue(subject.selectedDateDisplay.contains("August"))
        XCTAssertTrue(subject.selectedDateDisplay.contains("7"))
        XCTAssertTrue(subject.selectedDateDisplay.contains("2026"))

        var behindUTCStyle = Date.FormatStyle(date: .long, time: .omitted)
        behindUTCStyle.timeZone = losAngeles
        XCTAssertNotEqual(subject.selectedDateDisplay, storedDate.formatted(behindUTCStyle))
    }
}
