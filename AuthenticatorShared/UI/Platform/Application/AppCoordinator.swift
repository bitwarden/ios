import BitwardenSdk
import SwiftUI
import UIKit

// MARK: - AppCoordinator

/// A coordinator that manages the app's top-level navigation.
///
class AppCoordinator: Coordinator, HasRootNavigator {
    // MARK: Types

    /// The types of modules used by this coordinator.
    typealias Module = ItemListModule

    // MARK: Private Properties

    /// The context that the app is running within.
    private let appContext: AppContext

    /// The coordinator currently being displayed.
    private var childCoordinator: AnyObject?

    // MARK: Properties

    /// The module to use for creating child coordinators.
    let module: Module

    /// The navigator to use for presenting screens.
    private(set) weak var rootNavigator: RootNavigator?

    /// The service container used by the coordinator
    private let services: Services

    // MARK: Initialization

    /// Creates a new `AppCoordinator`.
    ///
    /// - Parameters:
    ///   - appContext: The context that the app is running within.
    ///   - appExtensionDelegate: A delegate used to communicate with the app extension.
    ///   - module: The module to use for creating child coordinators.
    ///   - rootNavigator: The navigator to use for presenting screens.
    ///   - services: The service container used by the coordinator.
    ///
    init(
        appContext: AppContext,
        module: Module,
        rootNavigator: RootNavigator,
        services: Services
    ) {
        self.appContext = appContext
        self.module = module
        self.rootNavigator = rootNavigator
        self.services = services
    }

    // MARK: Methods

    func handleEvent(_ event: AppEvent, context: AnyObject?) async {
        switch event {
        case .didStart:
            showItemList(route: .list)
        }
    }

    func navigate(to route: AppRoute, context _: AnyObject?) {
        switch route {
        case .onboarding:
            break
        }
    }

    func start() {
        // Nothing to do here - the initial route is specified by `AppProcessor` and this
        // coordinator doesn't need to navigate within the `Navigator` since it's the root.
    }

    // MARK: Private Methods

    /// Shows the Item List screen.
    ///
    /// - Parameter route: The item list route to show.
    ///
    private func showItemList(route: ItemListRoute) {
        if let coordinator = childCoordinator as? AnyCoordinator<ItemListRoute, ItemListEvent> {
            coordinator.navigate(to: route)
        } else {
            let stackNavigator = UINavigationController()
            let coordinator = module.makeItemListCoordinator(
                stackNavigator: stackNavigator
            )
            coordinator.start()
            coordinator.navigate(to: .list)
            childCoordinator = coordinator
            rootNavigator?.show(child: stackNavigator)
        }
    }
}
