import UIKit

extension UIViewController {
    /// Returns the topmost view controller starting from this view controller and navigating down the view hierarchy.
    ///
    /// - Returns: The topmost view controller from this view controller.
    ///
    func topmostViewController() -> UIViewController {
        if let presentedViewController {
            return presentedViewController.topmostViewController()
        } else {
            switch self {
            case let navigationController as UINavigationController:
                return navigationController.topViewController?.topmostViewController() ?? navigationController
            case let tabBarController as UITabBarController:
                return tabBarController.selectedViewController?.topmostViewController() ?? tabBarController
            default:
                return self
            }
        }
    }
}
