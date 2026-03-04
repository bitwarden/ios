import BitwardenKit
import Foundation

/// A coordinator that manages navigation for global modals.
///
public final class GlobalModalCoordinator: Coordinator, HasStackNavigator {
    // MARK: Types

    public typealias Services = HasConfigService
        & HasEnvironmentService
        & HasErrorAlertServices.ErrorAlertServices
        & HasErrorReporter
        & HasServerCommunicationConfigAPIService

    // MARK: Private Properties

    /// The services used by this coordinator.
    private let services: Services

    // MARK: Properties

    /// The stack navigator that is managed by this coordinator.
    public private(set) weak var stackNavigator: StackNavigator?

    // MARK: Initialization

    /// Creates a new `GlobalModalCoordinator`.
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

    public func navigate(
        to route: GlobalModalRoute,
        context: AnyObject?,
    ) {
        switch route {
        case let .dismissWithAction(onDismiss):
            stackNavigator?.dismiss(animated: true, completion: {
                onDismiss?.action()
            })
        case .syncWithBrowser:
            showSyncWithBrowser()
        }
    }

    /// Starts the coordinator.
    public func start() {}

    // MARK: Private Methods

    /// Configures and displays the sync with browser screen.
    private func showSyncWithBrowser() {
        let processor = SyncWithBrowserProcessor(
            coordinator: asAnyCoordinator(),
            delegate: self,
            services: services,
            state: SyncWithBrowserState(),
        )

        let view = SyncWithBrowserView(store: Store(processor: processor))
        stackNavigator?.replace(view)
    }
}

// MARK: - HasErrorAlertServices

extension GlobalModalCoordinator: HasErrorAlertServices {
    public var errorAlertServices: ErrorAlertServices { services }
}

// MARK: - SyncWithBrowserProcessorDelegate

extension GlobalModalCoordinator: SyncWithBrowserProcessorDelegate {
    func dismiss(action: DismissAction?) {
        navigate(to: .dismissWithAction(action))
    }
}
