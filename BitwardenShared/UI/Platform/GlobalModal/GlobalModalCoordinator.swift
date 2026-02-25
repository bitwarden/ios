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
        case .ssoSyncError:
            showSSOSyncError()
        }
    }

    /// Starts the coordinator.
    public func start() {}

    // MARK: Private Methods

    /// Configures and displays the debug menu.
    private func showSSOSyncError() {
        let processor = SsoSyncErrorProcessor(
            coordinator: asAnyCoordinator(),
            delegate: self,
            services: services,
            state: SsoSyncErrorState(),
        )

        let view = SsoSyncErrorView(store: Store(processor: processor))
        stackNavigator?.replace(view)
    }
}

// MARK: - HasErrorAlertServices

extension GlobalModalCoordinator: HasErrorAlertServices {
    public var errorAlertServices: ErrorAlertServices { services }
}

// MARK: - SsoSyncErrorProcessorDelegate

extension GlobalModalCoordinator: SsoSyncErrorProcessorDelegate {
    func dismiss(action: DismissAction?) {
        navigate(to: .dismissWithAction(action))
    }
}
