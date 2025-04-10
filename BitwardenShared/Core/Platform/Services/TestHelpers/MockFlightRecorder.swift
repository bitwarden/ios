import Combine

@testable import BitwardenShared

@MainActor
final class MockFlightRecorder: FlightRecorder {
    var disableFlightRecorderCalled = false
    var enableFlightRecorderCalled = false
    var enableFlightRecorderDuration: FlightRecorderLoggingDuration?
    var enableFlightRecorderResult: Result<Void, Error> = .success(())
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

    func isEnabledPublisher() async -> AnyPublisher<Bool, Never> {
        isEnabledSubject.eraseToAnyPublisher()
    }

    func log(_ message: String) async {
        logMessages.append(message)
    }
}
