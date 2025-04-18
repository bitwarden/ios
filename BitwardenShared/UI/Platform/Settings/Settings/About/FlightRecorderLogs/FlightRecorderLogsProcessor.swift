import Foundation

// MARK: - FlightRecorderLogsProcessor

/// The processor used to manage state and handle actions for the `FlightRecorderLogsView`.
///
final class FlightRecorderLogsProcessor: StateProcessor<
    FlightRecorderLogsState,
    FlightRecorderLogsAction,
    FlightRecorderLogsEffect
> {
    // MARK: Types

    typealias Services = HasErrorReporter

    // MARK: Private Properties

    /// The `Coordinator` that handles navigation.
    private let coordinator: AnyCoordinator<SettingsRoute, SettingsEvent>

    /// The services used by this processor.
    private var services: Services

    // MARK: Initialization

    /// Creates a new `FlightRecorderLogsProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The `Coordinator` that handles navigation.
    ///   - services: The services used by the processor.
    ///   - state: The initial state of the processor.
    ///
    init(
        coordinator: AnyCoordinator<SettingsRoute, SettingsEvent>,
        services: Services,
        state: FlightRecorderLogsState
    ) {
        self.coordinator = coordinator
        self.services = services
        super.init(state: state)
    }

    // MARK: Methods

    override func perform(_ effect: FlightRecorderLogsEffect) async {}

    override func receive(_ action: FlightRecorderLogsAction) {
        switch action {
        case .dismiss:
            coordinator.navigate(to: .dismiss)
        }
    }
}
