import BitwardenKit
@preconcurrency import Combine
import Foundation
import OSLog

// swiftlint:disable file_length

// MARK: - FlightRecorder

/// A protocol for a service which can temporarily be enabled to collect logs for debugging to a
/// local file.
///
protocol FlightRecorder: Sendable, BitwardenLogger {
    /// Deletes all inactive flight recorder logs. This will not delete the currently active log.
    ///
    func deleteInactiveLogs() async throws

    /// Deletes a flight recorder log.
    ///
    /// - Parameter log: The log to be deleted. This must not be the currently active log.
    ///
    func deleteLog(_ log: FlightRecorderLogMetadata) async throws

    /// Disables the collection of temporary debug logs.
    ///
    func disableFlightRecorder() async

    /// Enables the collection of temporary debug logs to a local file for a set duration.
    ///
    /// - Parameter duration: The duration that logging should be enabled for.
    ///
    func enableFlightRecorder(duration: FlightRecorderLoggingDuration) async throws

    /// Fetches the list of flight recorder logs currently stored on the device.
    ///
    /// - Returns: The list of logs currently stored on the device.
    ///
    func fetchLogs() async throws -> [FlightRecorderLogMetadata]

    /// A publisher which publishes the enabled status of the flight recorder.
    ///
    /// - Returns: A publisher for the enabled status of the flight recorder.
    ///
    func isEnabledPublisher() async -> AnyPublisher<Bool, Never>

    /// Appends a message to the active log, if logging is currently enabled.
    ///
    /// - Parameters:
    ///   - message: The message to append to the active log.
    ///   - file: The file that called the log method.
    ///   - line: The line number in the file that called the log method.
    ///
    func log(_ message: String, file: String, line: UInt) async
}

extension FlightRecorder {
    func log(_ message: String, file: String = #file, line: UInt = #line) async {
        await log(message, file: file, line: line)
    }

    nonisolated func log(_ message: String, file: String, line: UInt) {
        Task {
            await log(message, file: file, line: line)
        }
    }
}

// MARK: - FlightRecorderError

/// An enumeration of errors thrown by a `FlightRecorder`.
///
enum FlightRecorderError: Error {
    /// The stored flight recorder data doesn't exist.
    case dataUnavailable

    /// Deletion of the log isn't permitted if the log is the active log.
    case deletionNotPermitted

    /// The specified log wasn't found in the stored flight recorder data.
    case logNotFound
}

// MARK: - DefaultFlightRecorder

/// A default implementation of a `FlightRecorder`.
///
actor DefaultFlightRecorder {
    // MARK: Private Properties

    /// A subject containing the flight recorder data. This serves as a cache of the data after it
    /// has been fetched from disk. `getFlightRecorderData()`/`setFlightRecorderData()` should be
    /// used to get/set the data rather than using this directly.
    private let dataSubject = CurrentValueSubject<FlightRecorderData?, Never>(nil)

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

    /// A task that handles disabling the active log on its end date or deleting expired logs.
    private var logLifecycleTask: Task<Void, Never>?

    // MARK: Initialization

    /// Initialize a `DefaultFlightRecorder`.
    ///
    /// - Parameters:
    ///   - appInfoService: The service used by the application to get info about the app and device
    ///     it's running on.
    ///   - disableLogLifecycleTimerForTesting: Whether the log lifecycle timer should be disabled.
    ///     This should only be done while testing so that logs aren't removed while testing other
    ///     flight recorder functionality.
    ///   - errorReporter: The service used by the application to report non-fatal errors.
    ///   - fileManager: The file manager used to read and write files to the file system.
    ///   - stateService: The service used by the application to manage account state.
    ///   - timeProvider: The service used to get the present time.
    ///
    init(
        appInfoService: AppInfoService,
        disableLogLifecycleTimerForTesting: Bool = false,
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

        if !disableLogLifecycleTimerForTesting {
            Task {
                await dataSubject.send(stateService.getFlightRecorderData())
                await self.configureLogLifecycleTimer()
            }
        }
    }

    deinit {
        logLifecycleTask?.cancel()
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

    /// Configures a log lifecycle timer to listen for any changes to `FlightRecorderData` and then
    /// waits until the next lifecycle event in the data will occur.
    ///
    private func configureLogLifecycleTimer() async {
        for await data in dataSubject.values {
            logLifecycleTask?.cancel()
            guard let data else { continue }
            logLifecycleTask = Task { [weak self, timeProvider] in
                do {
                    if let nextLogLifecycleDate = data.nextLogLifecycleDate {
                        let components = Calendar.current.dateComponents(
                            [.second],
                            from: timeProvider.presentTime,
                            to: nextLogLifecycleDate
                        )
                        guard let seconds = components.second else { return }
                        // Sleep for a minimum of 1 second to prevent continuous looping if the
                        // timer's sleep time is slightly off from the true expiration.
                        let sleepSeconds = max(Double(seconds), UI.duration(1))

                        Logger.application.debug(
                            """
                            FlightRecorder: next log lifecycle: \(nextLogLifecycleDate), \
                            sleeping for \(sleepSeconds) seconds
                            """
                        )
                        try await Task.sleep(forSeconds: sleepSeconds)
                        await self?.evaluateLogLifecycles()
                    }
                } catch is CancellationError {
                    // No-op: don't log or alert for cancellation errors.
                } catch {
                    await self?.errorReporter.log(error: BitwardenError.generalError(
                        type: "Flight Recorder Log Lifecycle Timer Error",
                        message: "Error waiting for next flight recorder log lifecycle",
                        error: error
                    ))
                }
            }
        }
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

    /// Evaluates the data for any log lifecycle changes. This handles disabling the active log
    /// after the logging duration has elapsed and then removing any expired inactive logs.
    ///
    private func evaluateLogLifecycles() async {
        guard var data = dataSubject.value else { return }

        // Check if the active log should be disabled after its duration has elapsed.
        if let activeLog = data.activeLog, activeLog.endDate <= timeProvider.presentTime {
            Logger.application.debug("FlightRecorder: active log reached end date, deactivating")
            data.activeLog = nil
        }

        for (index, log) in data.inactiveLogs.enumerated() {
            guard log.expirationDate <= timeProvider.presentTime else { continue }

            Logger.application.debug(
                "FlightRecorder: removing expired log \(log.startDate) \(log.duration.shortDescription)"
            )

            do {
                try removeLog(at: fileURL(for: log))
            } catch {
                errorReporter.log(error: BitwardenError.generalError(
                    type: "Flight Recorder Remove Log Error",
                    message: "Unable to remove file for expired log",
                    error: error
                ))
            }

            data.inactiveLogs.remove(at: index)
        }

        await setFlightRecorderData(data)
    }

    /// Returns the file size for a log file.
    ///
    /// - Parameter log: The log metadata for determining the log file to get the file size for.
    /// - Returns: The file size of the log.
    ///
    private func fileSize(for log: FlightRecorderData.LogMetadata) -> String {
        do {
            let url = try fileURL(for: log)
            let attributes = try fileManager.attributesOfItem(atPath: url.path)
            let size = attributes[.size] as? Int64 ?? 0

            let formatter = ByteCountFormatter()
            formatter.allowsNonnumericFormatting = false
            formatter.countStyle = .binary
            return formatter.string(fromByteCount: size)
        } catch let error as NSError where error.domain == NSCocoaErrorDomain &&
            error.code == NSFileReadNoSuchFileError {
            return ""
        } catch {
            errorReporter.log(error: BitwardenError.generalError(
                type: "Flight Recorder File Size Error",
                message: "Unable to determine the log's file size",
                error: error
            ))
            return ""
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

    /// Gets the `FlightRecorderData`. If the data has already been loaded, it will be returned
    /// from `dataSubject`, otherwise it fetches the data from `StateService`.
    ///
    /// - Returns: The `FlightRecorderData` containing the list of flight recorder logs.
    ///
    private func getFlightRecorderData() async -> FlightRecorderData? {
        if let data = dataSubject.value {
            return data
        } else {
            let data = await stateService.getFlightRecorderData()
            if data != dataSubject.value {
                dataSubject.send(data)
            }
            return data
        }
    }

    /// Removes the log file at the specified URL.
    ///
    /// - Parameter url: The URL of the log file to remove.
    ///
    private func removeLog(at url: URL) throws {
        do {
            try fileManager.removeItem(at: url)
        } catch let error as NSError where error.domain == NSCocoaErrorDomain && error.code == NSFileNoSuchFileError {
            // No-op: if the file doesn't exist, continue without throwing.
        } catch {
            throw error
        }
    }

    /// Sets the `FlightRecorderData`. Using this ensures that both `dataSubject` and `StateService`
    /// get updates made to the data.
    ///
    /// - Parameter data: The `FlightRecorderData` to set.
    ///
    private func setFlightRecorderData(_ data: FlightRecorderData) async {
        await stateService.setFlightRecorderData(data)
        dataSubject.send(data)
    }
}

// MARK: - DefaultFlightRecorder + FlightRecorder

extension DefaultFlightRecorder: FlightRecorder {
    func deleteInactiveLogs() async throws {
        guard var data = await getFlightRecorderData() else {
            throw FlightRecorderError.dataUnavailable
        }

        for log in data.inactiveLogs {
            try removeLog(at: fileURL(for: log))
        }

        data.inactiveLogs.removeAll()
        await setFlightRecorderData(data)
    }

    func deleteLog(_ log: FlightRecorderLogMetadata) async throws {
        guard var data = await getFlightRecorderData() else {
            throw FlightRecorderError.dataUnavailable
        }
        guard data.activeLog?.id != log.id else {
            throw FlightRecorderError.deletionNotPermitted
        }
        guard let logMetadata = data.inactiveLogs.first(where: { $0.id == log.id }) else {
            throw FlightRecorderError.logNotFound
        }

        try removeLog(at: log.url)
        data.inactiveLogs.removeAll { $0.id == logMetadata.id }
        await setFlightRecorderData(data)
    }

    func disableFlightRecorder() async {
        guard var data = await getFlightRecorderData() else { return }
        data.activeLog = nil
        await setFlightRecorderData(data)
    }

    func enableFlightRecorder(duration: FlightRecorderLoggingDuration) async throws {
        let log = FlightRecorderData.LogMetadata(duration: duration, startDate: timeProvider.presentTime)
        try await createLogFile(for: log)

        var data = await getFlightRecorderData() ?? FlightRecorderData()
        data.activeLog = log
        await setFlightRecorderData(data)
    }

    func fetchLogs() async throws -> [FlightRecorderLogMetadata] {
        guard let data = await getFlightRecorderData() else { return [] }
        return try data.allLogs.map { log in
            try FlightRecorderLogMetadata(
                duration: log.duration,
                endDate: log.endDate,
                expirationDate: log.expirationDate,
                fileSize: fileSize(for: log),
                id: log.fileName,
                isActiveLog: log.id == data.activeLog?.id,
                startDate: log.startDate,
                url: fileURL(for: log)
            )
        }
    }

    func isEnabledPublisher() async -> AnyPublisher<Bool, Never> {
        _ = await getFlightRecorderData() // Ensure data has already been loaded to the subject.
        return dataSubject.map { $0?.activeLog != nil }.eraseToAnyPublisher()
    }

    func log(_ message: String, file: String, line: UInt) async {
        guard let log = await getFlightRecorderData()?.activeLog else { return }
        do {
            let timestampedMessage = "\(dateFormatter.string(from: timeProvider.presentTime)): \(message)\n"
            try await append(message: timestampedMessage, to: log)
        } catch {
            let fileName = URL(fileURLWithPath: file).lastPathComponent
            errorReporter.log(error: BitwardenError.generalError(
                type: "Flight Recorder Log Error",
                message: "\(fileName):\(line) Unable to write message to log: \(message)",
                error: error
            ))
        }
    }
}
