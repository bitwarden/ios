import BitwardenKit
@preconcurrency import Combine
import Foundation

// MARK: - FlightRecorder

/// A protocol for a service which can temporarily be enabled to collect logs for debugging to a
/// local file.
///
protocol FlightRecorder: Sendable {
    /// Disables the collection of temporary debug logs.
    ///
    func disableFlightRecorder() async

    /// Enables the collection of temporary debug logs to a local file for a set duration.
    ///
    /// - Parameter duration: The duration that logging should be enabled for.
    ///
    func enableFlightRecorder(duration: FlightRecorderLoggingDuration) async throws

    /// A publisher which publishes the enabled status of the flight recorder.
    ///
    /// - Returns: A publisher for the enabled status of the flight recorder.
    ///
    func isEnabledPublisher() async -> AnyPublisher<Bool, Never>

    /// Appends a message to the active log, if logging is currently enabled.
    ///
    /// - Parameter message: The message to append to the active log.
    ///
    func log(_ message: String) async
}

// MARK: - DefaultFlightRecorder

/// A default implementation of a `FlightRecorder`.
///
actor DefaultFlightRecorder {
    // MARK: Private Properties

    /// A subject containing the active log or `nil` if there's no active log. This serves as a
    /// cache of the active log metadata after it has been fetched from disk.
    private let activeLogSubject = CurrentValueSubject<FlightRecorderData.LogMetadata?, Never>(nil)

    /// The service used by the application to get info about the app and device it's running on.
    private let appInfoService: AppInfoService

    /// The service used by the application to report non-fatal errors.
    private let errorReporter: ErrorReporter

    /// The date formatter used to format the timestamp included with each message in the log.
    private let dateFormatter: ISO8601DateFormatter = {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.timeZone = .autoupdatingCurrent
        return dateFormatter
    }()

    /// The file manager used to read and write files to the file system.
    private let fileManager: FileManagerProtocol

    /// The service used by the application to manage account state.
    private let stateService: StateService

    /// The service used to get the present time.
    private let timeProvider: TimeProvider

    // MARK: Initialization

    /// Initialize a `DefaultFlightRecorder`.
    ///
    /// - Parameters:
    ///   - appInfoService: The service used by the application to get info about the app and device
    ///     it's running on.
    ///   - errorReporter: The service used by the application to report non-fatal errors.
    ///   - fileManager: The file manager used to read and write files to the file system.
    ///   - stateService: The service used by the application to manage account state.
    ///   - timeProvider: The service used to get the present time.
    ///
    init(
        appInfoService: AppInfoService,
        errorReporter: ErrorReporter,
        fileManager: FileManagerProtocol = FileManager.default,
        stateService: StateService,
        timeProvider: TimeProvider
    ) {
        self.appInfoService = appInfoService
        self.errorReporter = errorReporter
        self.fileManager = fileManager
        self.stateService = stateService
        self.timeProvider = timeProvider
    }

    // MARK: Private

    /// Appends a log message to the specified log.
    ///
    /// - Parameters:
    ///   - message: The message to append to the log.
    ///   - log: The log metadata for determining the log file to append the message to.
    ///
    private func append(message: String, to log: FlightRecorderData.LogMetadata) async throws {
        let url = try fileURL(for: log)
        try fileManager.append(Data(message.utf8), to: url)
    }

    /// Creates an initial log file and populates it with the log header.
    ///
    /// - Parameter log: The log metadata for determining the log file to create.
    ///
    private func createLogFile(for log: FlightRecorderData.LogMetadata) async throws {
        let userId = await (try? stateService.getActiveAccountId()) ?? "n/a"
        let contents = """
        Bitwarden iOS Flight Recorder
        Log Start: \(dateFormatter.string(from: log.startDate))
        Log Duration: \(log.duration.shortDescription)
        \(appInfoService.appInfoWithoutCopyrightString)
        User ID: \(userId)\n\n
        """

        let url = try fileURL(for: log)
        try fileManager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try fileManager.write(Data(contents.utf8), to: url)
        try fileManager.setIsExcludedFromBackup(true, to: url)
    }

    /// Fetches the active log metadata, either from `activeLogSubject` or from disk. After the log
    /// metadata has been loaded from disk, it's cached in the subject.
    ///
    /// - Returns: The active log, or `nil` if flight recorder logging isn't enabled.
    ///
    @discardableResult
    private func fetchActiveLog() async -> FlightRecorderData.LogMetadata? {
        if let activeLog = activeLogSubject.value {
            return activeLog
        } else if let activeLog = await stateService.getFlightRecorderData()?.activeLog {
            activeLogSubject.send(activeLog)
            return activeLog
        } else {
            return nil
        }
    }

    /// Returns a URL for a log file.
    ///
    /// - Parameter log: The log metadata for determining the log file's URL.
    /// - Returns: A URL for the log file.
    ///
    private func fileURL(for log: FlightRecorderData.LogMetadata) throws -> URL {
        try FileManager.default.flightRecorderLogURL().appendingPathComponent(log.fileName)
    }
}

// MARK: - DefaultFlightRecorder + FlightRecorder

extension DefaultFlightRecorder: FlightRecorder {
    func disableFlightRecorder() async {
        activeLogSubject.send(nil)

        guard var data = await stateService.getFlightRecorderData() else { return }
        data.activeLog = nil
        await stateService.setFlightRecorderData(data)
    }

    func enableFlightRecorder(duration: FlightRecorderLoggingDuration) async throws {
        let log = FlightRecorderData.LogMetadata(duration: duration, startDate: timeProvider.presentTime)
        try await createLogFile(for: log)

        var data = await stateService.getFlightRecorderData() ?? FlightRecorderData()
        data.activeLog = log
        await stateService.setFlightRecorderData(data)

        activeLogSubject.send(log)
    }

    func isEnabledPublisher() async -> AnyPublisher<Bool, Never> {
        await fetchActiveLog()
        return activeLogSubject.map { $0 != nil }.eraseToAnyPublisher()
    }

    func log(_ message: String) async {
        guard let log = await fetchActiveLog() else { return }
        do {
            let timestampedMessage = "\(dateFormatter.string(from: timeProvider.presentTime)): \(message)\n"
            try await append(message: timestampedMessage, to: log)
        } catch {
            errorReporter.log(error: BitwardenError.generalError(
                type: "Flight Recorder Log Error",
                message: "Unable to write message to log: \(message)",
                error: error
            ))
        }
    }
}
