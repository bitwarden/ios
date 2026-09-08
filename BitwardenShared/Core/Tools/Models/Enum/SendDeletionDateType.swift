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

    /// A time period of fourteen days.
    case fourteenDays

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
        case .fourteenDays: Localizations.xDays(14)
        case .thirtyDays: Localizations.xDays(30)
        case let .custom(customDate): customDate.dateTimeDisplay
        }
    }

    // MARK: Type Methods

    /// Returns the deletion date type matching the given number of hours.
    ///
    /// Maps to a preset case when `hours` matches a known preset (`1`, `24`, `48`, `72`, `168`,
    /// `336`, `720`); otherwise returns a `.custom` date `hours` from `originDate`. Used to
    /// represent a policy-enforced deletion date supplied as a number of hours.
    ///
    /// - Parameters:
    ///   - hours: The number of hours from `originDate` at which the Send should be deleted.
    ///   - originDate: The date the custom-fallback calculation is based on. Defaults to `Date()`.
    /// - Returns: The matching `SendDeletionDateType`.
    ///
    static func from(hours: Int, originDate: Date = Date()) -> SendDeletionDateType {
        switch hours {
        case 1: .oneHour
        case 24: .oneDay
        case 48: .twoDays
        case 72: .threeDays
        case 168: .sevenDays
        case 336: .fourteenDays
        case 720: .thirtyDays
        default: .custom(Calendar.current.date(byAdding: .hour, value: hours, to: originDate) ?? originDate)
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
        case .fourteenDays:
            Calendar.current.date(byAdding: .day, value: 14, to: originDate)
        case .thirtyDays:
            Calendar.current.date(byAdding: .day, value: 30, to: originDate)
        case let .custom(customDate):
            customDate
        }
    }
}
