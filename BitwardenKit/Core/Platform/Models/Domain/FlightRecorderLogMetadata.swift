import BitwardenResources
import Foundation

// MARK: - FlightRecorderLogMetadata

/// A data model containing the metadata associated with a flight recorder log.
///
public struct FlightRecorderLogMetadata: Equatable, Identifiable {
    // MARK: Properties

    /// The duration for how long the flight recorder was enabled for the log.
    public let duration: FlightRecorderLoggingDuration

    /// The date when the flight recorder for this log stops/stopped logging.
    public let endDate: Date

    /// The date when the flight recorder log will expire and be deleted.
    public let expirationDate: Date

    /// The size of the log file.
    public let fileSize: String

    /// A unique identifier for the log.
    public let id: String

    /// Whether this represents the active log.
    public let isActiveLog: Bool

    /// The date when the flight recorder for this log was turned on.
    public let startDate: Date

    /// A URL to the log file on disk.
    public let url: URL

    // MARK: Computed Properties

    /// The formatted date range for when the flight recorder was enabled for the log.
    public var formattedLoggingDateRange: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        dateFormatter.timeZone = .autoupdatingCurrent
        return "\(dateFormatter.string(from: startDate)) – \(dateFormatter.string(from: endDate))"
    }

    /// The accessibility label for the logging date range.
    public var loggingDateRangeAccessibilityLabel: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        return Localizations.dateRangeXToY(dateFormatter.string(from: startDate), dateFormatter.string(from: endDate))
    }

    // MARK: Initialization

    public init(
        duration: FlightRecorderLoggingDuration,
        endDate: Date,
        expirationDate: Date,
        fileSize: String,
        id: String,
        isActiveLog: Bool,
        startDate: Date,
        url: URL,
    ) {
        self.duration = duration
        self.endDate = endDate
        self.expirationDate = expirationDate
        self.fileSize = fileSize
        self.id = id
        self.isActiveLog = isActiveLog
        self.startDate = startDate
        self.url = url
    }

    // MARK: Methods

    /// The formatted date for when the log expires.
    ///
    /// - Parameter currentDate: The current date used to calculate how many days until the log expires.
    /// - Returns: The formatted expiration date.
    ///
    public func formattedExpiration(currentDate: Date = .now) -> String? {
        guard !isActiveLog else { return nil }

        let daysTilExpiration = Calendar.current.dateComponents(
            [.day],
            from: currentDate,
            to: expirationDate,
        ).day ?? 0

        switch daysTilExpiration {
        case 0:
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .none
            dateFormatter.timeStyle = .short
            return Localizations.expiresAtXTime(dateFormatter.string(from: expirationDate))
        case 1:
            return Localizations.expiresTomorrow
        default:
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .none
            return Localizations.expiresOnXDate(dateFormatter.string(from: expirationDate))
        }
    }
}
