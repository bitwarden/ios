import Combine

@testable import BitwardenKit

@MainActor
public final class MockFlightRecorder: FlightRecorder {
    public var activeLogSubject = CurrentValueSubject<FlightRecorderData.LogMetadata?, Never>(nil)
    public var deleteInactiveLogsCalled = false
    public var deleteInactiveLogsResult: Result<Void, Error> = .success(())
    public var deleteLogResult: Result<Void, Error> = .success(())
    public var deleteLogLogs = [FlightRecorderLogMetadata]()
    public var disableFlightRecorderCalled = false
    public var enableFlightRecorderCalled = false
    public var enableFlightRecorderDuration: FlightRecorderLoggingDuration?
    public var enableFlightRecorderResult: Result<Void, Error> = .success(())
    public var fetchLogsCalled = false
    public var fetchLogsResult: Result<[FlightRecorderLogMetadata], Error> = .success([])
    public var isEnabledSubject = CurrentValueSubject<Bool, Never>(false)
    public var logMessages = [String]()
    public var setFlightRecorderBannerDismissedCalled = false

    public nonisolated init() {}

    public func activeLogPublisher() async -> AnyPublisher<FlightRecorderData.LogMetadata?, Never> {
        activeLogSubject.eraseToAnyPublisher()
    }

    public func deleteInactiveLogs() async throws {
        deleteInactiveLogsCalled = true
        try deleteInactiveLogsResult.get()
    }

    public func deleteLog(_ log: FlightRecorderLogMetadata) async throws {
        deleteLogLogs.append(log)
        try deleteLogResult.get()
    }

    public func disableFlightRecorder() {
        disableFlightRecorderCalled = true
    }

    public func enableFlightRecorder(duration: FlightRecorderLoggingDuration) async throws {
        enableFlightRecorderCalled = true
        enableFlightRecorderDuration = duration
        try enableFlightRecorderResult.get()
    }

    public func fetchLogs() async throws -> [FlightRecorderLogMetadata] {
        fetchLogsCalled = true
        return try fetchLogsResult.get()
    }

    public func isEnabledPublisher() async -> AnyPublisher<Bool, Never> {
        isEnabledSubject.eraseToAnyPublisher()
    }

    public func log(_ message: String, file: String, line: UInt) async {
        logMessages.append(message)
    }

    public func setFlightRecorderBannerDismissed() async {
        setFlightRecorderBannerDismissedCalled = true
    }
}
