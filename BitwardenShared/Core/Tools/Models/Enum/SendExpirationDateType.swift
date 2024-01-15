import Foundation

// MARK: - SendExpirationDateType

/// An object that repsents the options available when setting the expiration period for a Send Item.
///
enum SendExpirationDateType: CaseIterable, Menuable {
    /// A never ending time period.
    case never

    /// A time period of one hour.
    case oneHour

    /// A time period of one day.
    case oneDay

    /// A time period of two days.
    case twoDays

    /// A time period of three days.
    case threeDays

    /// A time period of seven days.
    case sevenDays

    /// A time period of thirty days.
    case thirtyDays

    /// A custom time period.
    case custom

    // MARK: Properties

    var localizedName: String {
        switch self {
        case .never: Localizations.never
        case .oneHour: Localizations.oneHour
        case .oneDay: Localizations.oneDay
        case .twoDays: Localizations.twoDays
        case .threeDays: Localizations.threeDays
        case .sevenDays: Localizations.sevenDays
        case .thirtyDays: Localizations.thirtyDays
        case .custom: Localizations.custom
        }
    }

    // MARK: Methods

    /// Calculates the date representation of this value.
    ///
    /// - Parameters:
    ///   - originDate: The date that this calculation should be based on. Defaults to `Date()`.
    ///   - customValue: This value will be used when this value is `.custom`.
    ///
    func calculateDate(from originDate: Date = Date(), customValue: Date) -> Date? {
        switch self {
        case .never:
            nil
        case .oneHour:
            Calendar.current.date(byAdding: .hour, value: 1, to: originDate)
        case .oneDay:
            Calendar.current.date(byAdding: .day, value: 1, to: originDate)
        case .twoDays:
            Calendar.current.date(byAdding: .day, value: 2, to: originDate)
        case .threeDays:
            Calendar.current.date(byAdding: .day, value: 3, to: originDate)
        case .sevenDays:
            Calendar.current.date(byAdding: .day, value: 7, to: originDate)
        case .thirtyDays:
            Calendar.current.date(byAdding: .day, value: 30, to: originDate)
        case .custom:
            customValue
        }
    }
}
