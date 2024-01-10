import Foundation

// MARK: - SendDeletionDateType

/// An object that repsents the options available when setting the deletion period for a Send Item.
///
enum SendDeletionDateType: CaseIterable, Menuable {
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
    /// - Parameter customValue: This value will be used when this value is `.custom`.
    ///
    func calculateDate(customValue: Date) -> Date? {
        switch self {
        case .oneHour:
            Calendar.current.date(byAdding: .hour, value: 1, to: Date())
        case .oneDay:
            Calendar.current.date(byAdding: .day, value: 1, to: Date())
        case .twoDays:
            Calendar.current.date(byAdding: .day, value: 2, to: Date())
        case .threeDays:
            Calendar.current.date(byAdding: .day, value: 3, to: Date())
        case .sevenDays:
            Calendar.current.date(byAdding: .day, value: 7, to: Date())
        case .thirtyDays:
            Calendar.current.date(byAdding: .day, value: 30, to: Date())
        case .custom:
            customValue
        }
    }
}
