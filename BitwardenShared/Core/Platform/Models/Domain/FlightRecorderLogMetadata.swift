import BitwardenKit
import Foundation

// MARK: - FlightRecorderLogMetadata

/// A data model containing the metadata associated with a flight recorder log.
///
struct FlightRecorderLogMetadata: Equatable, Identifiable {
    // MARK: Properties

    /// The duration for how long the flight recorder was enabled for the log.
    let duration: FlightRecorderLoggingDuration

    /// The size of the log file.
    let fileSize: String

    /// A unique identifier for the log.
    let id: String

    /// The date when the flight recorder for this log was turned on.
    let startDate: Date

    // MARK: Computed Properties

    /// The date when the flight recorder for this log stops logging.
    var endDate: Date {
        Calendar.current.date(byAdding: duration, to: startDate) ?? startDate
    }

    /// The date when the flight recorder log will expire and be deleted.
    var expirationDate: Date {
        Calendar.current.date(
            byAdding: .day,
            value: Constants.flightRecorderLogExpirationDays,
            to: endDate
        ) ?? endDate
    }

    /// The formatted date range for when the flight recorder was enabled for the log.
    var formattedLoggingDateRange: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        dateFormatter.timeZone = .autoupdatingCurrent
        return "\(dateFormatter.string(from: startDate)) - \(dateFormatter.string(from: endDate))"
    }

    /// The accessibility label for the logging date range.
    var loggingDateRangeAccessibilityLabel: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        return Localizations.dateRangeXToY(dateFormatter.string(from: startDate), dateFormatter.string(from: endDate))
    }

    // MARK: Methods

    /// The formatted date for when the log expires.
    ///
    /// - Parameter currentDate: The current date used to calculate how many days until the log expires.
    /// - Returns: The formatted expiration date.
    ///
    func formattedExpiration(currentDate: Date = .now) -> String {
        let daysTilExpiration = Calendar.current.dateComponents(
            [.day],
            from: currentDate,
            to: expirationDate
        ).day ?? 0

        return switch daysTilExpiration {
        case 0: Localizations.expiresToday
        default: Localizations.expiresInXDays(daysTilExpiration)
        }
    }
}
