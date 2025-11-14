import UIKit

public extension UIViewController {
    /// Presents a view controller modally. Supports presenting on top of presented modals if necessary.
    ///
    /// - Parameters:
    ///   - viewController: The view controller to present.
    ///   - animated: Whether the transition should be animated.
    ///   - overFullscreen: Whether or not the presented modal should cover the full screen.
    ///   - onCompletion: A closure to call on completion.
    ///
    func present(
        _ viewController: UIViewController,
        animated: Bool = UI.animated,
        overFullscreen: Bool = false,
        onCompletion: (() -> Void)? = nil,
    ) {
        var presentedChild = presentedViewController
        var availablePresenter: UIViewController? = self
        while presentedChild != nil, presentedChild?.isBeingDismissed == false {
            availablePresenter = presentedChild
            presentedChild = presentedChild?.presentedViewController
        }
        if overFullscreen {
            viewController.modalPresentationStyle = .overFullScreen
        }
        if let popoverPresentationController = viewController.popoverPresentationController,
           popoverPresentationController.sourceView == nil,
           popoverPresentationController.barButtonItem == nil,
           let parentView = availablePresenter?.view {
            // Provide a default source view and rect when presenting a popover if one isn't
            // already specified. This prevents a crash when presenting popovers on iPadOS.
            popoverPresentationController.sourceView = parentView
            popoverPresentationController.sourceRect = CGRect(
                x: parentView.bounds.midX, y: parentView.bounds.midY, width: 0, height: 0,
            )
            popoverPresentationController.permittedArrowDirections = []
        }
        availablePresenter?.present(
            viewController,
            animated: animated,
            completion: onCompletion,
        )
    }

    /// Returns the topmost view controller starting from this view controller and navigating down the view hierarchy.
    ///
    /// - Returns: The topmost view controller from this view controller.
    ///
    func topmostViewController() -> UIViewController {
        if let presentedViewController {
            presentedViewController.topmostViewController()
        } else {
            switch self {
            case let navigationController as UINavigationController:
                navigationController.topViewController?.topmostViewController() ?? navigationController
            case let tabBarController as UITabBarController:
                tabBarController.selectedViewController?.topmostViewController() ?? tabBarController
            default:
                self
            }
        }
    }
}
