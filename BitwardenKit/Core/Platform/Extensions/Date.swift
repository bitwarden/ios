import Foundation

public extension Date {
    /// A convenience initializer for `Date` to specify a specific point in time.
    init(
        year: Int,
        month: Int,
        day: Int,
        hour: Int = 0,
        minute: Int = 0,
        second: Int = 0,
        nanosecond: Int = 0,
        timeZone: TimeZone = TimeZone(secondsFromGMT: 0)!
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
            nanosecond: nanosecond
        )
        self = dateComponents.date!
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
