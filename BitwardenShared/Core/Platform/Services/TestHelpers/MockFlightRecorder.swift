import Combine

@testable import BitwardenShared

@MainActor
final class MockFlightRecorder: FlightRecorder {
    var disableFlightRecorderCalled = false
    var enableFlightRecorderCalled = false
    var enableFlightRecorderDuration: FlightRecorderLoggingDuration?
    var isEnabledSubject = CurrentValueSubject<Bool, Never>(false)

    nonisolated init() {}

    func disableFlightRecorder() {
        disableFlightRecorderCalled = true
    }

    func enableFlightRecorder(duration: FlightRecorderLoggingDuration) async {
        enableFlightRecorderCalled = true
        enableFlightRecorderDuration = duration
    }

    func isEnabledPublisher() async -> AnyPublisher<Bool, Never> {
        isEnabledSubject.eraseToAnyPublisher()
    }
}
