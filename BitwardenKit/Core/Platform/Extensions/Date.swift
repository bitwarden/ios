import Foundation

public extension Date {
    /// A string to display the current datetime in the desired format taking locale into consideration.
    var dateTimeDisplay: String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale.current
        dateFormatter.setLocalizedDateFormatFromTemplate("MMM d, yyyy")

        let timeFormatter = DateFormatter()
        timeFormatter.locale = Locale.current
        timeFormatter.setLocalizedDateFormatFromTemplate("jj:mm")

        let dateString = dateFormatter.string(from: self)
        let timeString = timeFormatter.string(from: self)
        return "\(dateString), \(timeString)"
    }

    /// The date formatted as an ISO 8601 calendar-date string (`yyyy-MM-dd`), e.g. `2023-06-23`.
    ///
    /// This is date-only, with no time component, suitable for storing day/month/year fields such
    /// as a driver's license expiration or a passport date of birth.
    var iso8601DateOnlyString: String {
        Date.iso8601DateOnlyFormatter().string(from: self)
    }

    /// A convenience initializer for `Date` to specify a specific point in time.
    init(
        year: Int,
        month: Int,
        day: Int,
        hour: Int = 0,
        minute: Int = 0,
        second: Int = 0,
        nanosecond: Int = 0,
        timeZone: TimeZone = TimeZone(secondsFromGMT: 0)!,
    ) {
        let calendar = Calendar(identifier: .gregorian)
        let dateComponents = DateComponents(
            calendar: calendar,
            timeZone: timeZone,
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute,
            second: second,
            nanosecond: nanosecond,
        )
        self = dateComponents.date!
    }

    /// Creates a `Date` from an ISO 8601 calendar-date string (`yyyy-MM-dd`).
    ///
    /// Returns `nil` if the string isn't a valid calendar date (e.g. `2023-02-30`), making it safe
    /// to use when converting stored string fields back into dates.
    ///
    /// - Parameter iso8601DateOnlyString: The calendar-date string to parse, e.g. `2023-06-23`.
    ///
    init?(iso8601DateOnlyString string: String) {
        guard let date = Date.iso8601DateOnlyFormatter().date(from: string) else { return nil }
        self = date
    }

    // MARK: Methods

    /// Returns a date that is set to midnight on the day that is seven days in the future.
    ///
    static func midnightOneWeekFromToday() -> Date? {
        let calendar = Calendar.current
        guard let date = calendar.date(byAdding: .day, value: 7, to: Date()) else { return nil }
        guard let date = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: date) else { return nil }
        return date
    }
}

private extension Date {
    /// Builds a strict, locale-independent formatter for ISO 8601 calendar dates (`yyyy-MM-dd`).
    ///
    /// A fresh formatter is returned on each call to avoid sharing a non-`Sendable` instance across
    /// concurrency domains. Uses the POSIX locale and UTC time zone so output and parsing are
    /// deterministic regardless of the device locale, and disables lenient parsing so invalid dates
    /// such as `2023-02-30` fail to parse rather than rolling over.
    static func iso8601DateOnlyFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.isLenient = false
        return formatter
    }
}
