import Foundation

// MARK: - FlightRecorderData

/// A data model containing the persisted data necessary for the flight recorder. This stores the
/// metadata for the active and any inactive logs.
///
public struct FlightRecorderData: Codable, Equatable {
    // MARK: Properties

    /// The current log, if the flight recorder is active.
    public var activeLog: LogMetadata? {
        didSet {
            guard let oldValue, oldValue.id != activeLog?.id else { return }
            inactiveLogs.insert(oldValue, at: 0)
        }
    }

    /// A list of previously recorded and inactive logs, which remain available on device until they
    /// are deleted by the user or expire and are deleted by the app.
    public var inactiveLogs: [LogMetadata] = []

    // MARK: Computed Properties

    /// The full list of logs containing the active and any inactive logs.
    public var allLogs: [LogMetadata] {
        ([activeLog] + inactiveLogs).compactMap(\.self)
    }

    /// The upcoming date in which either the active log needs to end logging or an inactive log
    /// expires and needs to be removed.
    public var nextLogLifecycleDate: Date? {
        let dates = [activeLog?.endDate].compactMap(\.self) + inactiveLogs.map(\.expirationDate)
        return dates.min()
    }

    // MARK: Initialization

    /// Initialize `FlightRecorderData`.
    ///
    /// - Parameters:
    ///   - activeLog: The current log, if the flight recorder is active.
    ///   - inactiveLogs: A list of previously recorded and inactive logs, which remain available
    ///     on device until they are deleted by the user or expire and are deleted by the app.
    ///
    public init(activeLog: LogMetadata? = nil, inactiveLogs: [LogMetadata] = []) {
        self.activeLog = activeLog
        self.inactiveLogs = inactiveLogs
    }
}

public extension FlightRecorderData {
    /// A data model containing the metadata for a flight recorder log.
    ///
    struct LogMetadata: Codable, Equatable, Identifiable {
        // MARK: Properties

        /// The duration for how long the flight recorder was enabled for the log.
        public let duration: FlightRecorderLoggingDuration

        /// The date when the logging will end.
        public let endDate: Date

        /// The file name of the file on disk.
        public let fileName: String

        /// Whether the flight recorder toast banner has been dismissed for this log.
        @DefaultFalse public var isBannerDismissed = false

        /// The date the logging was started.
        public let startDate: Date

        // MARK: Computed Properties

        /// The date when the flight recorder log will expire and be deleted.
        public var expirationDate: Date {
            Calendar.current.date(
                byAdding: .day,
                value: Constants.flightRecorderLogExpirationDays,
                to: endDate,
            ) ?? endDate
        }

        /// The formatted end date for the log.
        public var formattedEndDate: String {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .none
            return dateFormatter.string(from: endDate)
        }

        /// The formatted end time for the log.
        public var formattedEndTime: String {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .none
            dateFormatter.timeStyle = .short
            return dateFormatter.string(from: endDate)
        }

        public var id: String {
            fileName
        }

        // MARK: Initialization

        /// Initialize a `LogMetadata`.
        ///
        /// - Parameters:
        ///   - duration: The duration for how long the flight recorder was enabled for the log.
        ///   - startDate: The date the logging was started.
        ///
        public init(duration: FlightRecorderLoggingDuration, startDate: Date) {
            self.duration = duration
            self.startDate = startDate

            endDate = Calendar.current.date(byAdding: duration, to: startDate) ?? startDate

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd-HH-mm-ss"
            fileName = "flight_recorder_\(dateFormatter.string(from: startDate)).txt"
        }
    }
}
