import Combine

@testable import BitwardenShared

@MainActor
final class MockFlightRecorder: FlightRecorder {
    var disableFlightRecorderCalled = false
    var enableFlightRecorderCalled = false
    var enableFlightRecorderDuration: FlightRecorderLoggingDuration?
    var enableFlightRecorderResult: Result<Void, Error> = .success(())
    var fetchLogsResult: Result<[FlightRecorderLogMetadata], Error> = .success([])
    var isEnabledSubject = CurrentValueSubject<Bool, Never>(false)
    var logMessages = [String]()

    nonisolated init() {}

    func disableFlightRecorder() {
        disableFlightRecorderCalled = true
    }

    func enableFlightRecorder(duration: FlightRecorderLoggingDuration) async throws {
        enableFlightRecorderCalled = true
        enableFlightRecorderDuration = duration
        try enableFlightRecorderResult.get()
    }

    func fetchLogs() async throws -> [FlightRecorderLogMetadata] {
        try fetchLogsResult.get()
    }

    func isEnabledPublisher() async -> AnyPublisher<Bool, Never> {
        isEnabledSubject.eraseToAnyPublisher()
    }

    func log(_ message: String, file: String, line: UInt) async {
        logMessages.append(message)
    }
}
