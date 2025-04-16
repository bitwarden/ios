@preconcurrency import Combine

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
    func enableFlightRecorder(duration: FlightRecorderLoggingDuration) async

    /// A publisher which publishes the enabled status of the flight recorder.
    ///
    /// - Returns: A publisher for the enabled status of the flight recorder.
    ///
    func isEnabledPublisher() async -> AnyPublisher<Bool, Never>
}

// MARK: - DefaultFlightRecorder

/// A default implementation of a `FlightRecorder`.
///
@MainActor
final class DefaultFlightRecorder {
    // MARK: Private Properties

    /// A subject containing the enable status of the flight recorder.
    private let isEnabledSubject = CurrentValueSubject<Bool, Never>(false)

    /// The service used by the application to manage account state.
    private let stateService: StateService

    /// The service used to get the present time.
    private let timeProvider: TimeProvider

    // MARK: Initialization

    /// Initialize a `DefaultFlightRecorder`.
    ///
    /// - Parameters:
    ///   - stateService: The service used by the application to manage account state.
    ///   - timeProvider: The service used to get the present time.
    ///
    init(stateService: StateService, timeProvider: TimeProvider) {
        self.stateService = stateService
        self.timeProvider = timeProvider
    }
}

// MARK: - DefaultFlightRecorder + FlightRecorder

extension DefaultFlightRecorder: FlightRecorder {
    func disableFlightRecorder() async {
        isEnabledSubject.send(false)
    }

    func enableFlightRecorder(duration: FlightRecorderLoggingDuration) async {
        isEnabledSubject.send(true)
    }

    func isEnabledPublisher() async -> AnyPublisher<Bool, Never> {
        isEnabledSubject.eraseToAnyPublisher()
    }
}
