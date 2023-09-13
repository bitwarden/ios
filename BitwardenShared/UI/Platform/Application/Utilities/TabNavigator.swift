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
    func navigator<Tab: RawRepresentable>(for tab: Tab) -> Navigator? where Tab.RawValue == Int
}

// MARK: - UITabBarController

extension UITabBarController: TabNavigator {
    public var rootViewController: UIViewController {
        self
    }

    public func navigator<Tab: RawRepresentable>(for tab: Tab) -> Navigator? where Tab.RawValue == Int {
        viewControllers?[tab.rawValue] as? Navigator
    }
}
