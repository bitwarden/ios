import Foundation

// MARK: - EnableFlightRecorderProcessor

/// The processor used to manage state and handle actions for the `EnableFlightRecorderView`.
///
final class EnableFlightRecorderProcessor: StateProcessor<
    EnableFlightRecorderState,
    EnableFlightRecorderAction,
    EnableFlightRecorderEffect
> {
    // MARK: Types

    typealias Services = HasErrorReporter

    // MARK: Private Properties

    /// The `Coordinator` that handles navigation.
    private let coordinator: AnyCoordinator<SettingsRoute, SettingsEvent>

    /// The services used by this processor.
    private var services: Services

    // MARK: Initialization

    /// Creates a new `EnableFlightRecorderProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The `Coordinator` that handles navigation.
    ///   - services: The services used by the processor.
    ///   - state: The initial state of the processor.
    ///
    init(
        coordinator: AnyCoordinator<SettingsRoute, SettingsEvent>,
        services: Services,
        state: EnableFlightRecorderState
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
        // TODO: PM-19577 Enable logging
        coordinator.navigate(to: .dismiss)
    }
}
