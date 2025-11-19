import UIKit

// MARK: - FlightRecorderCoordinator

/// A coordinator that manages navigation for the flight recorder.
///
public final class FlightRecorderCoordinator: Coordinator, HasStackNavigator {
    // MARK: Types

    public typealias Services = HasErrorAlertServices.ErrorAlertServices
        & HasErrorReporter
        & HasFlightRecorder
        & HasTimeProvider

    /// The services used by this coordinator.
    private let services: Services

    // MARK: Properties

    /// The stack navigator that is managed by this coordinator.
    public private(set) weak var stackNavigator: StackNavigator?

    // MARK: Initialization

    /// Creates a new `FlightRecorderCoordinator`.
    ///
    /// - Parameters:
    ///   - services: The services used by this coordinator.
    ///   - stackNavigator: The stack navigator that is managed by this coordinator.
    ///
    public init(
        services: Services,
        stackNavigator: StackNavigator,
    ) {
        self.services = services
        self.stackNavigator = stackNavigator
    }

    // MARK: Methods

    public func navigate(to route: FlightRecorderRoute, context: AnyObject?) {
        switch route {
        case .dismiss:
            stackNavigator?.dismiss()
        case .enableFlightRecorder:
            showEnableFlightRecorder()
        case .flightRecorderLogs:
            showFlightRecorderLogs()
        case let .shareURL(url):
            showShareSheet([url])
        case let .shareURLs(urls):
            showShareSheet(urls)
        }
    }

    public func start() {}

    // MARK: Private

    /// Shows the enable flight recorder screen.
    ///
    private func showEnableFlightRecorder() {
        let processor = EnableFlightRecorderProcessor(
            coordinator: asAnyCoordinator(),
            services: services,
            state: EnableFlightRecorderState(),
        )
        stackNavigator?.present(EnableFlightRecorderView(store: Store(processor: processor)))
    }

    /// Shows the flight recorder logs screen.
    ///
    private func showFlightRecorderLogs() {
        let processor = FlightRecorderLogsProcessor(
            coordinator: asAnyCoordinator(),
            services: services,
            state: FlightRecorderLogsState(),
        )
        let view = FlightRecorderLogsView(store: Store(processor: processor), timeProvider: services.timeProvider)
        stackNavigator?.present(view)
    }

    /// Shows the share sheet to share one or more items.
    ///
    /// - Parameter items: The items to share.
    ///
    private func showShareSheet(_ items: [Any]) {
        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
        stackNavigator?.present(activityVC)
    }
}

// MARK: - HasErrorAlertServices

extension FlightRecorderCoordinator: HasErrorAlertServices {
    public var errorAlertServices: ErrorAlertServices { services }
}
