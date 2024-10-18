import Foundation

/// A coordinator that manages navigation for the debug menu.
///
final class DebugMenuCoordinator: Coordinator, HasStackNavigator {
    // MARK: Types

    typealias Services = HasAppSettingsStore
        & HasConfigService
        & HasErrorReporter

    // MARK: Private Properties

    /// The services used by this coordinator.
    private let services: Services

    // MARK: Properties

    /// The stack navigator that is managed by this coordinator.
    private(set) weak var stackNavigator: StackNavigator?

    // MARK: Initialization

    /// Creates a new `DebugMenuCoordinator`.
    ///
    /// - Parameters:
    ///   - services: The services used by this coordinator.
    ///   - stackNavigator: The stack navigator that is managed by this coordinator.
    ///
    init(
        services: Services,
        stackNavigator: StackNavigator
    ) {
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
            stackNavigator?.dismiss()
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
