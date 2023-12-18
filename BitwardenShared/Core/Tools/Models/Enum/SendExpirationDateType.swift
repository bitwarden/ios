// MARK: - SendExpirationDateType

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
}
