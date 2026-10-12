import BitwardenKit
import Foundation
import Testing

@testable import TestHarnessShared

// MARK: - DateFieldPickerShowcaseStateTests

/// Tests for `DateFieldPickerShowcaseState`.
///
struct DateFieldPickerShowcaseStateTests {
    // MARK: Tests

    /// `selectedDateDisplay` is an empty string when no date has been selected.
    @Test
    func selectedDateDisplay_isEmptyWhenUnset() {
        let subject = DateFieldPickerShowcaseState()
        #expect(subject.selectedDateDisplay.isEmpty)
    }

    /// `selectedDateDisplay` shows the same calendar day that was selected, even when the stored
    /// UTC-anchored date falls on the previous day in the device's local time zone. This guards
    /// against a regression where the showcase read the stored date back with an implicit local
    /// time zone and displayed the day before the one the user picked.
    @Test
    func selectedDateDisplay_matchesSelectedDayRegardlessOfDeviceTimeZone() {
        let losAngeles = TimeZone(identifier: "America/Los_Angeles")!
        let selectedLocalDay = Date(year: 2026, month: 8, day: 7, timeZone: losAngeles)
        let storedDate = selectedLocalDay.asUTCCalendarDay(from: losAngeles)

        var subject = DateFieldPickerShowcaseState()
        subject.selectedDate = storedDate

        #expect(subject.selectedDateDisplay == storedDate.longCalendarDateDisplay)
        #expect(subject.selectedDateDisplay.contains("August"))
        #expect(subject.selectedDateDisplay.contains("7"))
        #expect(subject.selectedDateDisplay.contains("2026"))

        var behindUTCStyle = Date.FormatStyle(date: .long, time: .omitted)
        behindUTCStyle.timeZone = losAngeles
        #expect(subject.selectedDateDisplay != storedDate.formatted(behindUTCStyle))
    }
}
