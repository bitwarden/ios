// MARK: - SettingsCoordinatorDelegate

/// An object that is signaled when specific circumstances in the application flow have been encountered.
///
@MainActor
public protocol SettingsCoordinatorDelegate: AnyObject {
    /// Called when the user has been logged out.
    ///
    func didLogout()
}

// MARK: - SettingsCoordinator

/// A coordinator that manages navigation in the settings tab.
///
final class SettingsCoordinator: Coordinator {
    // MARK: Types

    typealias Services = HasSettingsRepository

    // MARK: Properties

    /// The delegate for this coordinator, used to notify when the user logs out.
    weak var delegate: SettingsCoordinatorDelegate?

    /// The services used by this coordinator.
    let services: Services

    /// The stack navigator that is managed by this coordinator.
    let stackNavigator: StackNavigator

    // MARK: Initialization

    /// Creates a new `SettingsCoordinator`.
    ///
    /// - Parameters:
    ///   - delegate: The delegate for this coordinator, used to notify when the user logs out.
    ///   - services: The services used by this coordinator.
    ///   - stackNavigator: The stack navigator that is managed by this coordinator.
    ///
    init(
        delegate: SettingsCoordinatorDelegate,
        services: Services,
        stackNavigator: StackNavigator
    ) {
        self.delegate = delegate
        self.services = services
        self.stackNavigator = stackNavigator
    }

    // MARK: Methods

    func hideLoadingOverlay() {
        stackNavigator.hideLoadingOverlay()
    }

    func navigate(to route: SettingsRoute, context: AnyObject?) {
        switch route {
        case let .alert(alert):
            stackNavigator.present(alert)
        case .logout:
            delegate?.didLogout()
        case .settings:
            showSettings()
        }
    }

    func showLoadingOverlay(_ state: LoadingOverlayState) {
        stackNavigator.showLoadingOverlay(state)
    }

    func start() {
        navigate(to: .settings)
    }

    // MARK: Private Methods

    /// Shows the settings screen.
    ///
    private func showSettings() {
        let processor = SettingsProcessor(
            coordinator: asAnyCoordinator(),
            services: services,
            state: SettingsState()
        )
        let view = SettingsView(store: Store(processor: processor))
        stackNavigator.push(view)
    }
}
