import Foundation

// MARK: - FlightRecorderData

/// A data model containing the persisted data necessary for the flight recorder. This stores the
/// metadata for the active and any archived logs.
///
struct FlightRecorderData: Codable, Equatable {
    // MARK: Properties

    /// The current log, if the flight recorder is active.
    var activeLog: LogMetadata? {
        didSet {
            guard let oldValue else { return }
            archivedLogs.insert(oldValue, at: 0)
        }
    }

    /// A list of previously recorded and inactive logs, which remain available on device until they
    /// are deleted by the user or expire and are deleted by the app.
    var archivedLogs: [LogMetadata] = []

    // MARK: Computed Properties

    /// The full list of logs containing the active and any archived logs.
    var allLogs: [LogMetadata] {
        ([activeLog] + archivedLogs).compactMap { $0 }
    }
}

extension FlightRecorderData {
    /// A data model containing the metadata for a flight recorder log.
    ///
    struct LogMetadata: Codable, Equatable, Identifiable {
        // MARK: Properties

        /// The duration for how long the flight recorder was enabled for the log.
        let duration: FlightRecorderLoggingDuration

        /// The date when the logging will end.
        let endDate: Date

        /// The file name of the file on disk.
        let fileName: String

        /// The date the logging was started.
        let startDate: Date

        // MARK: Computed Properties

        var id: String {
            fileName
        }

        // MARK: Initialization

        /// Initialize a `LogMetadata`.
        ///
        /// - Parameters:
        ///   - duration: The duration for how long the flight recorder was enabled for the log.
        ///   - startDate: The date the logging was started.
        ///
        init(duration: FlightRecorderLoggingDuration, startDate: Date) {
            self.duration = duration
            self.startDate = startDate

            endDate = Calendar.current.date(byAdding: duration, to: startDate) ?? startDate

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd-HH-mm-ss"
            fileName = "flight_recorder_\(dateFormatter.string(from: startDate)).txt"
        }
    }
}
