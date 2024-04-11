import OSLog
import SwiftUI

// MARK: - ItemListCoordinator

/// A coordinator that manages navigation on the Item List screen.
///
final class ItemListCoordinator: Coordinator, HasStackNavigator {
    // MARK: - Types

    typealias Module = AuthenticatorItemModule
        & ItemListModule

    typealias Services = HasTimeProvider
        & ItemListProcessor.Services

    // MARK: - Private Properties

    /// The module used by this coordinator to create child coordinators.
    private let module: Module

    /// The services used by this coordinator.
    private let services: Services

    // MARK: - Properties

    /// The stack navigator that is managed by this coordinator.
    private(set) weak var stackNavigator: StackNavigator?

    // MARK: - Initialization

    /// Creates a new `ItemListCoordinator`.
    ///
    ///  - Parameters:
    ///   - module: The module used by this coordinator to create child coordinators.
    ///   - services: The services used by this coordinator.
    ///   - stackNavigator: The stack navigator that is managed by this coordinator.
    ///
    init(
        module: Module,
        services: Services,
        stackNavigator: StackNavigator
    ) {
        self.module = module
        self.services = services
        self.stackNavigator = stackNavigator
    }

    // MARK: - Methods

    func handleEvent(_ event: ItemListEvent, context: AnyObject?) async {
        switch event {
        case .showScanCode:
            guard let delegate = context as? AuthenticatorKeyCaptureDelegate else { return }
            await showCamera(delegate: delegate)
        }
    }

    func navigate(to route: ItemListRoute, context: AnyObject?) {
        switch route {
        case .addItem:
            break
        case let .editItem(item):
            showToken(route: .editAuthenticatorItem(item))
        case .list:
            showList()
        case .setupTotpManual:
            guard let delegate = context as? AuthenticatorKeyCaptureDelegate else { return }
            showManualTotp(delegate: delegate)
        case let .viewItem(id):
            showToken(route: .viewToken(id: id))
        }
    }

    func start() {}

    // MARK: - Private Methods

    /// Shows the totp camera setup screen.
    ///
    private func showCamera(delegate: AuthenticatorKeyCaptureDelegate) async {
        let navigationController = UINavigationController()
        let coordinator = AuthenticatorKeyCaptureCoordinator(
            delegate: delegate,
            services: services,
            stackNavigator: navigationController
        )
        coordinator.start()

        await coordinator.handleEvent(.showScanCode, context: self)
        stackNavigator?.present(navigationController, overFullscreen: true)
    }

    /// Shows the totp manual setup screen.
    ///
    private func showManualTotp(delegate: AuthenticatorKeyCaptureDelegate) {
        let navigationController = UINavigationController()
        let coordinator = AuthenticatorKeyCaptureCoordinator(
            delegate: delegate,
            services: services,
            stackNavigator: navigationController
        ).asAnyCoordinator()
        coordinator.start()
        coordinator.navigate(to: .manualKeyEntry, context: nil)
        stackNavigator?.present(navigationController)
    }

    /// Shows the list of items
    ///
    func showList() {
        let processor = ItemListProcessor(
            coordinator: asAnyCoordinator(),
            services: services,
            state: ItemListState()
        )
        let store = Store(processor: processor)
        let view = ItemListView(
            store: store,
            timeProvider: services.timeProvider
        )
        stackNavigator?.replace(view, animated: false)
    }

    /// Presents a token coordinator, which will navigate to the provided route.
    ///
    /// - Parameter route: The route to navigate to in the coordinator.
    ///
    private func showToken(route: AuthenticatorItemRoute) {
        let navigationController = UINavigationController()
        let coordinator = module.makeAuthenticatorItemCoordinator(stackNavigator: navigationController)
        coordinator.start()
        coordinator.navigate(to: route, context: self)

        stackNavigator?.present(navigationController)
    }
}
