import Foundation

extension Date {
    /// Returns a date that is set to midnight on the day that is seven days in the future.
    ///
    static func midnightOneWeekFromToday() -> Date? {
        let calendar = Calendar.current
        guard let date = calendar.date(byAdding: .day, value: 7, to: Date()) else { return nil }
        guard let date = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: date) else { return nil }
        return date
    }
}
