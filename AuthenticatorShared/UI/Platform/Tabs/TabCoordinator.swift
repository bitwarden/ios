import BitwardenKit
import SwiftUI
import UIKit

// MARK: - TabCoordinator

/// A coordinator that manages navigation in the tab interface.
///
final class TabCoordinator: Coordinator, HasTabNavigator {
    // MARK: Types

    /// The module types required by this coordinator for creating child coordinators.
    typealias Module = ItemListModule
        & NavigatorBuilderModule
        & SettingsModule

    // MARK: Properties

    /// The root navigator used to display this coordinator's interface.
    weak var rootNavigator: (any RootNavigator)?

    /// The tab navigator that is managed by this coordinator.
    private(set) weak var tabNavigator: TabNavigator?

    // MARK: Private Properties

    /// The error reporter used by the tab coordinator.
    private var errorReporter: ErrorReporter

    /// The coordinator used to navigate to `ItemListRoute`s.
    private var itemListCoordinator: AnyCoordinator<ItemListRoute, ItemListEvent>?

    /// A delegate of the `ItemListCoordinator`.
    private weak var itemListDelegate: ItemListCoordinatorDelegate?

    /// The module used to create child coordinators.
    private let module: Module

    /// A task to handle organization streams.
    private var organizationStreamTask: Task<Void, Error>?

    /// The coordinator used to navigate to `SettingsRoute`s.
    private var settingsCoordinator: AnyCoordinator<SettingsRoute, SettingsEvent>?

    // MARK: Initialization

    /// Creates a new `TabCoordinator`.
    ///
    /// - Parameters:
    ///   - errorReporter: The error reporter used by the tab coordinator.
    ///   - itemListDelegate: A delegate of the `ItemListCoordinator`.
    ///   - module: The module used to create child coordinators.
    ///   - rootNavigator: The root navigator used to display this coordinator's interface.
    ///   - tabNavigator: The tab navigator that is managed by this coordinator.
    ///
    init(
        errorReporter: ErrorReporter,
        itemListDelegate: ItemListCoordinatorDelegate,
        module: Module,
        rootNavigator: RootNavigator,
        tabNavigator: TabNavigator,
    ) {
        self.errorReporter = errorReporter
        self.itemListDelegate = itemListDelegate
        self.module = module
        self.rootNavigator = rootNavigator
        self.tabNavigator = tabNavigator
    }

    deinit {
        organizationStreamTask?.cancel()
        organizationStreamTask = nil
    }

    // MARK: Methods

    func navigate(to route: TabRoute, context: AnyObject?) {
        tabNavigator?.selectedIndex = route.index
        switch route {
        case let .itemList(itemListRoute):
            itemListCoordinator?.navigate(to: itemListRoute, context: context)
        case let .settings(settingsRoute):
            settingsCoordinator?.navigate(to: settingsRoute, context: context)
        }
    }

    func start() {
        guard let itemListDelegate, let rootNavigator, let tabNavigator else { return }

        rootNavigator.show(child: tabNavigator)

        let itemListNavigator = module.makeNavigationController()
        itemListNavigator.navigationBar.prefersLargeTitles = true
        itemListCoordinator = module.makeItemListCoordinator(
            delegate: itemListDelegate,
            stackNavigator: itemListNavigator,
        )

        let settingsNavigator = module.makeNavigationController()
        settingsNavigator.navigationBar.prefersLargeTitles = true
        let settingsCoordinator = module.makeSettingsCoordinator(
            stackNavigator: settingsNavigator,
        )
        settingsCoordinator.start()
        self.settingsCoordinator = settingsCoordinator

        let tabsAndNavigators: [TabRoute: Navigator] = [
            .itemList(.list): itemListNavigator,
            .settings(.settings): settingsNavigator,
        ]
        tabNavigator.setNavigators(tabsAndNavigators)

        tabsAndNavigators.forEach { key, value in
            (value as? UINavigationController)?.tabBarItem.accessibilityIdentifier = key.accessibilityIdentifier
        }
    }

    func showErrorAlert(error: any Error, tryAgain: (() async -> Void)?, onDismissed: (() -> Void)?) async {
        errorReporter.log(error: BitwardenError.generalError(
            type: "TabCoordinator: `showErrorAlert` Not Supported",
            message: "`showErrorAlert(error:tryAgain:onDismissed:)` is not supported from TabCoordinator.",
        ))
    }
}
