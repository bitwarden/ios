import UIKit

// MARK: - UITabBarController

extension UITabBarController: TabNavigator {
    public var rootViewController: UIViewController? {
        self
    }

    public func navigator<Tab: TabRepresentable>(for tab: Tab) -> Navigator? {
        viewControllers?[tab.index] as? Navigator
    }

    public func setNavigators<Tab: Hashable & TabRepresentable>(_ tabs: [Tab: Navigator]) {
        viewControllers = tabs
            .sorted { $0.key.index < $1.key.index }
            .compactMap { tab in
                guard let viewController = tab.value.rootViewController else { return nil }
                viewController.tabBarItem.title = tab.key.title
                viewController.tabBarItem.image = tab.key.image
                viewController.tabBarItem.selectedImage = tab.key.selectedImage
                return viewController
            }
    }
}
