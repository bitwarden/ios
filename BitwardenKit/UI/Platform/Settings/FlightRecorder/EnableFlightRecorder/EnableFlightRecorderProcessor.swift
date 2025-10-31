import Foundation

// MARK: - EnableFlightRecorderProcessor

/// The processor used to manage state and handle actions for the `EnableFlightRecorderView`.
///
final class EnableFlightRecorderProcessor: StateProcessor<
    EnableFlightRecorderState,
    EnableFlightRecorderAction,
    EnableFlightRecorderEffect,
> {
    // MARK: Types

    typealias Services = HasErrorReporter
        & HasFlightRecorder

    // MARK: Private Properties

    /// The `Coordinator` that handles navigation.
    private let coordinator: AnyCoordinator<FlightRecorderRoute, Void>

    /// The services used by this processor.
    private let services: Services

    // MARK: Initialization

    /// Creates a new `EnableFlightRecorderProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The `Coordinator` that handles navigation.
    ///   - services: The services used by the processor.
    ///   - state: The initial state of the processor.
    ///
    init(
        coordinator: AnyCoordinator<FlightRecorderRoute, Void>,
        services: Services,
        state: EnableFlightRecorderState,
    ) {
        self.coordinator = coordinator
        self.services = services
        super.init(state: state)
    }

    // MARK: Methods

    override func perform(_ effect: EnableFlightRecorderEffect) async {
        switch effect {
        case .save:
            await saveAndEnableFlightRecorder()
        }
    }

    override func receive(_ action: EnableFlightRecorderAction) {
        switch action {
        case .dismiss:
            coordinator.navigate(to: .dismiss)
        case let .loggingDurationChanged(loggingDuration):
            state.loggingDuration = loggingDuration
        }
    }

    // MARK: Private Methods

    /// Saves the logging duration and enables the flight recorder.
    ///
    private func saveAndEnableFlightRecorder() async {
        do {
            try await services.flightRecorder.enableFlightRecorder(duration: state.loggingDuration)
            coordinator.navigate(to: .dismiss)
        } catch {
            services.errorReporter.log(error: error)
            await coordinator.showErrorAlert(error: error)
        }
    }
}
