import BitwardenKit
import BitwardenResources
import Foundation

// MARK: - SendDeletionDateType

/// An object that represents the options available when setting the deletion period for a Send Item.
///
enum SendDeletionDateType: Menuable {
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
    case custom(Date)

    // MARK: Properties

    var localizedName: String {
        switch self {
        case .oneHour: Localizations.xHours(1)
        case .oneDay: Localizations.xDays(1)
        case .twoDays: Localizations.xDays(2)
        case .threeDays: Localizations.xDays(3)
        case .sevenDays: Localizations.xDays(7)
        case .thirtyDays: Localizations.xDays(30)
        case let .custom(customDate): customDate.dateTimeDisplay
        }
    }

    // MARK: Methods

    /// Calculates the date representation of this value.
    ///
    /// - Parameters originDate: The date that this calculation should be based on. Defaults to `Date()`.
    ///
    func calculateDate(from originDate: Date = Date()) -> Date? {
        switch self {
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
        case let .custom(customDate):
            customDate
        }
    }
}
