import BitwardenKit
import XCTest

class DateTests: BitwardenTestCase {
    // MARK: Tests

    /// `iso8601DateOnlyString` formats a date as a `yyyy-MM-dd` calendar-date string.
    func test_iso8601DateOnlyString() {
        let date = Date(year: 2023, month: 6, day: 23)
        XCTAssertEqual(date.iso8601DateOnlyString, "2023-06-23")
    }

    /// `iso8601DateOnlyString` zero-pads single-digit months and days.
    func test_iso8601DateOnlyString_zeroPadded() {
        let date = Date(year: 2024, month: 1, day: 5)
        XCTAssertEqual(date.iso8601DateOnlyString, "2024-01-05")
    }

    /// `init(iso8601DateOnlyString:)` parses a valid calendar-date string into a date.
    func test_initISO8601DateOnlyString_valid() {
        let date = Date(iso8601DateOnlyString: "2023-06-23")
        XCTAssertEqual(date, Date(year: 2023, month: 6, day: 23))
    }

    /// `init(iso8601DateOnlyString:)` round-trips with `iso8601DateOnlyString`.
    func test_initISO8601DateOnlyString_roundTrip() {
        let original = Date(year: 1999, month: 12, day: 31)
        let parsed = Date(iso8601DateOnlyString: original.iso8601DateOnlyString)
        XCTAssertEqual(parsed, original)
    }

    /// `init(iso8601DateOnlyString:)` returns `nil` for an impossible calendar date.
    func test_initISO8601DateOnlyString_invalidDate() {
        XCTAssertNil(Date(iso8601DateOnlyString: "2023-02-30"))
    }

    /// `init(iso8601DateOnlyString:)` returns `nil` for a malformed string.
    func test_initISO8601DateOnlyString_malformed() {
        XCTAssertNil(Date(iso8601DateOnlyString: ""))
        XCTAssertNil(Date(iso8601DateOnlyString: "not-a-date"))
        XCTAssertNil(Date(iso8601DateOnlyString: "06/23/2023"))
    }

    /// `asLocalCalendarDay(in:)` keeps the same calendar day for a UTC-anchored date when converted
    /// to a positive-offset time zone.
    func test_asLocalCalendarDay_positiveOffset() {
        let utcDate = Date(year: 2023, month: 6, day: 23)
        let localDate = utcDate.asLocalCalendarDay(in: TimeZone(identifier: "Pacific/Auckland")!)
        XCTAssertEqual(
            localDate,
            Date(year: 2023, month: 6, day: 23, timeZone: TimeZone(identifier: "Pacific/Auckland")!),
        )
    }

    /// `asLocalCalendarDay(in:)` keeps the same calendar day for a UTC-anchored date when converted
    /// to a negative-offset time zone.
    func test_asLocalCalendarDay_negativeOffset() {
        let utcDate = Date(year: 2023, month: 6, day: 23)
        let localDate = utcDate.asLocalCalendarDay(in: TimeZone(identifier: "America/Los_Angeles")!)
        XCTAssertEqual(
            localDate,
            Date(year: 2023, month: 6, day: 23, timeZone: TimeZone(identifier: "America/Los_Angeles")!),
        )
    }

    /// `asUTCCalendarDay(from:)` keeps the same calendar day when converting a date picked in a
    /// positive-offset time zone back to its UTC-anchored form.
    func test_asUTCCalendarDay_positiveOffset() {
        let localDate = Date(year: 2023, month: 6, day: 23, timeZone: TimeZone(identifier: "Pacific/Auckland")!)
        let utcDate = localDate.asUTCCalendarDay(from: TimeZone(identifier: "Pacific/Auckland")!)
        XCTAssertEqual(utcDate, Date(year: 2023, month: 6, day: 23))
    }

    /// `asUTCCalendarDay(from:)` keeps the same calendar day when converting a date picked in a
    /// negative-offset time zone back to its UTC-anchored form.
    func test_asUTCCalendarDay_negativeOffset() {
        let localDate = Date(year: 2023, month: 6, day: 23, timeZone: TimeZone(identifier: "America/Los_Angeles")!)
        let utcDate = localDate.asUTCCalendarDay(from: TimeZone(identifier: "America/Los_Angeles")!)
        XCTAssertEqual(utcDate, Date(year: 2023, month: 6, day: 23))
    }

    /// `asLocalCalendarDay(in:)` and `asUTCCalendarDay(from:)` round-trip across a range of time
    /// zones, so a day picked in a local-time UI control always survives conversion to and from the
    /// UTC-anchored storage form.
    func test_asLocalAndUTCCalendarDay_roundTrip() {
        let zones = [
            "UTC", "Pacific/Auckland", "Pacific/Kiritimati", "America/Los_Angeles", "Etc/GMT+12",
        ].map { TimeZone(identifier: $0)! }
        let original = Date(year: 2023, month: 6, day: 23)

        for zone in zones {
            let roundTripped = original.asLocalCalendarDay(in: zone).asUTCCalendarDay(from: zone)
            XCTAssertEqual(roundTripped, original, "Round trip failed for time zone \(zone.identifier)")
        }
    }

    /// `longCalendarDateDisplay` renders a UTC-anchored date as the same calendar day regardless of
    /// the device's current time zone.
    func test_longCalendarDateDisplay() {
        let date = Date(year: 2023, month: 6, day: 23)
        var expectedStyle = Date.FormatStyle(date: .long, time: .omitted)
        expectedStyle.timeZone = TimeZone(identifier: "UTC")!
        XCTAssertEqual(date.longCalendarDateDisplay, date.formatted(expectedStyle))
    }
}
