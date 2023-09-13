import UIKit

// MARK: - TabNavigator

/// A navigator that displays a child navigators in a tab interface.
///
@MainActor
public protocol TabNavigator: Navigator {
    /// The index of the navigator associated with the currently selected tab item.
    var selectedIndex: Int { get set }

    /// Returns the child navigator for the specified tab.
    ///
    /// - Parameter tab: The tab which should be returned by the navigator.
    /// - Returns: The child navigator for the specified tab.
    ///
    func navigator<Tab: TabRepresentable>(for tab: Tab) -> Navigator?

    /// Sets the child navigators for their tabs.
    ///
    /// This method replaces all existing tabs with this new set of tabs.
    ///
    /// Tabs are ordered based on their `index` value.
    ///
    /// - Parameter tabs: The tab -> navigator relationship.
    ///
    func setNavigators<Tab: Hashable & TabRepresentable>(_ tabs: [Tab: Navigator])
}

// MARK: - UITabBarController

extension UITabBarController: TabNavigator {
    public var rootViewController: UIViewController {
        self
    }

    public func navigator<Tab: TabRepresentable>(for tab: Tab) -> Navigator? {
        viewControllers?[tab.index] as? Navigator
    }

    public func setNavigators<Tab: Hashable & TabRepresentable>(_ tabs: [Tab: Navigator]) {
        viewControllers = tabs
            .sorted { $0.key.index < $1.key.index }
            .map { tab in
                let viewController = tab.value.rootViewController
                viewController.tabBarItem.title = tab.key.title
                viewController.tabBarItem.image = tab.key.image
                viewController.tabBarItem.selectedImage = tab.key.selectedImage
                return viewController
            }
    }
}
