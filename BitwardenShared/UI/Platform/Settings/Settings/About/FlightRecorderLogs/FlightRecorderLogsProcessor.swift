import BitwardenResources
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
        & HasFlightRecorder

    // MARK: Private Properties

    /// The `Coordinator` that handles navigation.
    private let coordinator: AnyCoordinator<SettingsRoute, SettingsEvent>

    /// The services used by this processor.
    private let services: Services

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

    override func perform(_ effect: FlightRecorderLogsEffect) async {
        switch effect {
        case .loadData:
            await loadData()
        }
    }

    override func receive(_ action: FlightRecorderLogsAction) {
        switch action {
        case let .delete(log):
            delete(log: log)
        case .deleteAll:
            deleteAllLogs()
        case .dismiss:
            coordinator.navigate(to: .dismiss)
        case let .share(log):
            coordinator.navigate(to: .shareURL(log.url))
        case .shareAll:
            let urls = state.logs.map(\.url)
            coordinator.navigate(to: .shareURLs(urls))
        case let .toastShown(newValue):
            state.toast = newValue
        }
    }

    // MARK: Private

    /// Shows the confirm deletion alert and calls the action closure if the user confirms they
    /// want to delete the log files.
    ///
    /// - Parameters:
    ///   - isBulkDeletion: Whether the user is attempting to delete multiple logs.
    ///   - action: The closure to perform if the user confirms the deletion.
    ///
    private func confirmDeletion(isBulkDeletion: Bool, action: @MainActor @escaping () async -> Void) {
        coordinator.showAlert(.confirmDeleteLog(isBulkDeletion: isBulkDeletion, action: action))
    }

    /// Shows the deletion confirmation alert and then deletes all inactive logs if the user confirms.
    ///
    private func deleteAllLogs() {
        confirmDeletion(isBulkDeletion: true) {
            do {
                try await self.services.flightRecorder.deleteInactiveLogs()
                self.state.toast = Toast(title: Localizations.allLogsDeleted)
                await self.loadData()
            } catch {
                self.services.errorReporter.log(error: error)
                await self.coordinator.showErrorAlert(error: error)
            }
        }
    }

    /// Shows the deletion confirmation alert and then deletes the log if the user confirms.
    ///
    private func delete(log: FlightRecorderLogMetadata) {
        confirmDeletion(isBulkDeletion: false) {
            do {
                try await self.services.flightRecorder.deleteLog(log)
                self.state.toast = Toast(title: Localizations.logDeleted)
                await self.loadData()
            } catch {
                self.services.errorReporter.log(error: error)
                await self.coordinator.showErrorAlert(error: error)
            }
        }
    }

    /// Loads the data for the view.
    ///
    private func loadData() async {
        do {
            state.logs = try await services.flightRecorder.fetchLogs()
        } catch {
            services.errorReporter.log(error: error)
            await coordinator.showErrorAlert(error: error)
        }
    }
}
