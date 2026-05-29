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
}
