/// An enum that represents how long to enable the flight recorder.
///
enum LoggingDuration: CaseIterable, Menuable {
    /// The flight recorder is enabled for one hour.
    case oneHour

    /// The flight recorder is enabled for eight hours.
    case eightHours

    /// The flight recorder is enabled for 24 hours.
    case twentyFourHours

    /// The flight recorder is enabled for one week.
    case oneWeek

    var localizedName: String {
        switch self {
        case .oneHour: Localizations.oneHour
        case .eightHours: Localizations.xHours(8)
        case .twentyFourHours: Localizations.xHours(24)
        case .oneWeek: Localizations.oneWeek
        }
    }
}
