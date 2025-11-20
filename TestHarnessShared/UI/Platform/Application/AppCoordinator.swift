import BitwardenKit
import SwiftUI
import UIKit

// MARK: - AppCoordinator

/// A coordinator that manages the app's top-level navigation.
///
@MainActor
class AppCoordinator: Coordinator, HasRootNavigator {
    // MARK: Types

    /// The types of modules used by this coordinator.
    typealias Module = RootModule

    // MARK: Private Properties

    /// The coordinator currently being displayed.
    private var childCoordinator: AnyObject?

    // MARK: Properties

    /// The module to use for creating child coordinators.
    let module: Module

    /// The navigator to use for presenting screens.
    private(set) weak var rootNavigator: RootNavigator?

    /// The service container used by the coordinator.
    private let services: Services

    // MARK: Initialization

    /// Creates a new `AppCoordinator`.
    ///
    /// - Parameters:
    ///   - module: The module to use for creating child coordinators.
    ///   - rootNavigator: The navigator to use for presenting screens.
    ///   - services: The service container used by the coordinator.
    ///
    init(
        module: Module,
        rootNavigator: RootNavigator,
        services: Services,
    ) {
        self.module = module
        self.rootNavigator = rootNavigator
        self.services = services
    }

    // MARK: Methods

    func handleEvent(_ event: AppEvent, context: AnyObject?) async {
        switch event {
        case .didStart:
            showRoot(route: .scenarioPicker)
        }
    }

    func navigate(to route: AppRoute, context _: AnyObject?) {
        switch route {
        case let .root(rootRoute):
            showRoot(route: rootRoute)
        }
    }

    func start() {
        // Nothing to do here - the initial route is specified by `AppProcessor` and this
        // coordinator doesn't need to navigate within the `Navigator` since it's the root.
    }

    // MARK: Private Methods

    /// Shows the root route.
    ///
    /// - Parameter route: The root route to show.
    ///
    private func showRoot(route: RootRoute) {
        if let coordinator = childCoordinator as? AnyCoordinator<RootRoute, Void> {
            coordinator.navigate(to: route)
        } else {
            guard let rootNavigator else { return }
            let navigationController = UINavigationController()
            navigationController.navigationBar.prefersLargeTitles = true
            let coordinator = module.makeRootCoordinator(
                stackNavigator: navigationController,
            )
            coordinator.start()
            coordinator.navigate(to: route)
            childCoordinator = coordinator
            rootNavigator.show(child: navigationController)
        }
    }
}

// MARK: - HasErrorAlertServices

extension AppCoordinator: HasErrorAlertServices {
    var errorAlertServices: ErrorAlertServices { services }
}
