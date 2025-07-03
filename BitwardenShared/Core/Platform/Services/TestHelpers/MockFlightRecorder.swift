import Combine

@testable import BitwardenShared

@MainActor
final class MockFlightRecorder: FlightRecorder {
    var activeLogSubject = CurrentValueSubject<FlightRecorderData.LogMetadata?, Never>(nil)
    var deleteInactiveLogsCalled = false
    var deleteInactiveLogsResult: Result<Void, Error> = .success(())
    var deleteLogResult: Result<Void, Error> = .success(())
    var deleteLogLogs = [FlightRecorderLogMetadata]()
    var disableFlightRecorderCalled = false
    var enableFlightRecorderCalled = false
    var enableFlightRecorderDuration: FlightRecorderLoggingDuration?
    var enableFlightRecorderResult: Result<Void, Error> = .success(())
    var fetchLogsCalled = false
    var fetchLogsResult: Result<[FlightRecorderLogMetadata], Error> = .success([])
    var isEnabledSubject = CurrentValueSubject<Bool, Never>(false)
    var logMessages = [String]()
    var setFlightRecorderBannerDismissedCalled = false

    nonisolated init() {}

    func activeLogPublisher() async -> AnyPublisher<FlightRecorderData.LogMetadata?, Never> {
        activeLogSubject.eraseToAnyPublisher()
    }

    func deleteInactiveLogs() async throws {
        deleteInactiveLogsCalled = true
        try deleteInactiveLogsResult.get()
    }

    func deleteLog(_ log: FlightRecorderLogMetadata) async throws {
        deleteLogLogs.append(log)
        try deleteLogResult.get()
    }

    func disableFlightRecorder() {
        disableFlightRecorderCalled = true
    }

    func enableFlightRecorder(duration: FlightRecorderLoggingDuration) async throws {
        enableFlightRecorderCalled = true
        enableFlightRecorderDuration = duration
        try enableFlightRecorderResult.get()
    }

    func fetchLogs() async throws -> [FlightRecorderLogMetadata] {
        fetchLogsCalled = true
        return try fetchLogsResult.get()
    }

    func isEnabledPublisher() async -> AnyPublisher<Bool, Never> {
        isEnabledSubject.eraseToAnyPublisher()
    }

    func log(_ message: String, file: String, line: UInt) async {
        logMessages.append(message)
    }

    func setFlightRecorderBannerDismissed() async {
        setFlightRecorderBannerDismissedCalled = true
    }
}
