import BitwardenSdk
import SwiftUI

// MARK: - ItemsCoordinator

/// A coordinator that manages navigation on the Token List screen.
///
final class ItemsCoordinator: Coordinator, HasStackNavigator {
    // MARK: - Types

    typealias Module = ItemsModule

    typealias Services = HasTimeProvider
        & ItemsProcessor.Services

    // MARK: - Private Properties

    /// The module used by this coordinator to create child coordinators.
    private let module: Module

    /// The services used by this coordinator.
    private let services: Services

    // MARK: - Properties

    /// The stack navigator that is managed by this coordinator.
    private(set) weak var stackNavigator: StackNavigator?

    // MARK: - Initialization

    /// Creates a new `ItemsCoordinator`.
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

    func handleEvent(_ event: ItemsEvent, context: AnyObject?) async {
        switch event {
        case .showScanCode:
            guard let delegate = context as? AuthenticatorKeyCaptureDelegate else { return }
            await showCamera(delegate: delegate)
        }
    }

    func navigate(to route: ItemsRoute, context: AnyObject?) {
        switch route {
        case .addItem:
            break
        case .list:
            showList()
        case .setupTotpManual:
            guard let delegate = context as? AuthenticatorKeyCaptureDelegate else { return }
            showManualTotp(delegate: delegate)

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

    func showList() {
        let processor = ItemsProcessor(
            coordinator: asAnyCoordinator(),
            services: services,
            state: ItemsState()
        )
        let store = Store(processor: processor)
        let view = ItemsView(
            store: store,
            timeProvider: services.timeProvider
        )
        stackNavigator?.replace(view, animated: false)
    }
}
