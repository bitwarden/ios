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

    func handleEvent(_ event: ItemsEvent, context: AnyObject?) async {}

    func navigate(to route: ItemsRoute, context: AnyObject?) {
        switch route {
        case .list:
            showList()
        }
    }

    func start() {}

    // MARK: - Private Methods

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
