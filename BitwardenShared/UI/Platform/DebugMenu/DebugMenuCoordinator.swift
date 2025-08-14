import Foundation

/// An object that is notified when the debug menu is dismissed.
///
protocol DebugMenuCoordinatorDelegate: AnyObject {
    /// The debug menu has been dismissed.
    ///
    func didDismissDebugMenu()
}

/// A coordinator that manages navigation for the debug menu.
///
final class DebugMenuCoordinator: Coordinator, HasStackNavigator {
    // MARK: Types

    typealias Services = HasAppSettingsStore
        & HasConfigService
        & HasErrorAlertServices.ErrorAlertServices
        & HasErrorReporter

    // MARK: Private Properties

    /// The delegate for this coordinator, which is notified when the debug menu is dismissed.
    private weak var delegate: DebugMenuCoordinatorDelegate?

    /// The services used by this coordinator.
    private let services: Services

    // MARK: Properties

    /// The stack navigator that is managed by this coordinator.
    private(set) weak var stackNavigator: StackNavigator?

    // MARK: Initialization

    /// Creates a new `DebugMenuCoordinator`.
    ///
    /// - Parameters:
    ///   - delegate: The delegate for this coordinator, which is notified when the debug menu is dismissed.
    ///   - services: The services used by this coordinator.
    ///   - stackNavigator: The stack navigator that is managed by this coordinator.
    ///
    init(
        delegate: DebugMenuCoordinatorDelegate,
        services: Services,
        stackNavigator: StackNavigator
    ) {
        self.delegate = delegate
        self.services = services
        self.stackNavigator = stackNavigator
    }

    // MARK: Methods

    func navigate(
        to route: DebugMenuRoute,
        context: AnyObject?
    ) {
        switch route {
        case .dismiss:
            stackNavigator?.dismiss {
                self.delegate?.didDismissDebugMenu()
            }
        }
    }

    /// Starts the process of displaying the debug menu.
    func start() {
        showDebugMenu()
    }

    // MARK: Private Methods

    /// Configures and displays the debug menu.
    private func showDebugMenu() {
        let processor = DebugMenuProcessor(
            coordinator: asAnyCoordinator(),
            services: services,
            state: DebugMenuState()
        )

        let view = DebugMenuView(store: Store(processor: processor))
        stackNavigator?.replace(view)
    }
}

// MARK: - HasErrorAlertServices

extension DebugMenuCoordinator: HasErrorAlertServices {
    var errorAlertServices: ErrorAlertServices { services }
}
