import BitwardenResources
import Foundation

/// An enum that represents how long to enable the flight recorder.
///
enum FlightRecorderLoggingDuration: CaseIterable, Codable, Menuable {
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

    /// A short string representation of the duration (e.g. 1h, 8h, 1w).
    var shortDescription: String {
        switch self {
        case .oneHour: "1h"
        case .eightHours: "8h"
        case .twentyFourHours: "24h"
        case .oneWeek: "1w"
        }
    }
}

// MARK: - Calendar + FlightRecorderLoggingDuration

extension Calendar {
    /// Adds the specified `FlightRecorderLoggingDuration` to the given `Date`.
    ///
    /// - Parameters:
    ///   - duration: The logging duration to add to a date.
    ///   - date: The date to add the logging duration to.
    /// - Returns: The resulting date with the logging duration added.
    ///
    func date(byAdding duration: FlightRecorderLoggingDuration, to date: Date) -> Date? {
        switch duration {
        case .oneHour:
            self.date(byAdding: .hour, value: 1, to: date)
        case .eightHours:
            self.date(byAdding: .hour, value: 8, to: date)
        case .twentyFourHours:
            self.date(byAdding: .hour, value: 24, to: date)
        case .oneWeek:
            self.date(byAdding: .day, value: 7, to: date)
        }
    }
}
