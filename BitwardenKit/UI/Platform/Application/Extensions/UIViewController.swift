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
        availablePresenter?.safePresent(
            viewController,
            animated: animated,
            completion: onCompletion,
        )
    }

    /// Safely presents a view controller by ensuring no presentation is already in progress. This helps
    /// avoid potential race conditions with presenting while another view is being dismissed.
    ///
    /// This method checks if a presentation is currently in progress and waits if necessary before
    /// presenting the view controller. If a view controller is already being presented and being
    /// dismissed, it will retry after a short delay, up to a maximum of 10 attempts (~3 seconds).
    ///
    /// - Parameters:
    ///   - viewController: The view controller to present.
    ///   - animated: Whether the transition should be animated.
    ///   - remainingAttempts: The number of retry attempts remaining before giving up. Defaults to `10`.
    ///   - completion: A closure to call on completion.
    ///
    func safePresent(
        _ viewController: UIViewController,
        animated: Bool,
        remainingAttempts: Int = 10,
        completion: (() -> Void)?,
    ) {
        guard presentedViewController == nil || presentedViewController?.isBeingDismissed == false else {
            guard remainingAttempts > 0 else { return }
            // Already presenting something, but it's in the process of dismissing. Wait and retry.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.safePresent(
                    viewController,
                    animated: animated,
                    remainingAttempts: remainingAttempts - 1,
                    completion: completion,
                )
            }
            return
        }
        present(viewController, animated: animated, completion: completion)
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
