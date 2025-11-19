import SwiftUI
import UIKit

/// An object to manage showing and hiding toasts.
@MainActor
public enum ToastDisplayHelper {
    // MARK: Type Properties

    /// The duration in seconds of the show and hide transitions.
    static let transitionDuration: TimeInterval = 0.2

    /// A value that is used to identify the toast within the view hierarchy in
    /// order to remove it.
    public static let toastTag = 2000

    // MARK: Type Methods

    /// Shows the toast over the specified view controller.
    ///
    /// - Parameters:
    ///   - parentViewController: The parent view controller that the toast should be shown above.
    ///   - toast: The toast to display.
    ///   - additionalBottomPadding: Additional padding to apply to the bottom of the toast.
    ///   - duration: The number of seconds the toast should display for.
    ///
    public static func show(
        in parentViewController: UIViewController,
        toast: Toast,
        additionalBottomPadding: CGFloat = 0,
        duration: TimeInterval = 3,
    ) {
        guard parentViewController.view.window?.viewWithTag(toastTag) == nil,
              let window = parentViewController.view.window
        else { return }

        // Create the toast view.
        let viewController = UIHostingController(rootView: ToastView(toast: .constant(toast)))
        viewController.view.layer.backgroundColor = nil
        viewController.view.layer.opacity = 0
        viewController.view.tag = toastTag

        // Position the toast view on the window with appropriate bottom padding above the tab bar.
        window.addSubview(viewController.view)
        let bottomPadding = getSafeArea(from: parentViewController).bottom + 16 + additionalBottomPadding
        viewController.view.translatesAutoresizingMaskIntoConstraints = false
        viewController.view.bottomAnchor.constraint(equalTo: window.bottomAnchor, constant: -bottomPadding)
            .isActive = true
        viewController.view.leadingAnchor.constraint(equalTo: window.leadingAnchor).isActive = true
        viewController.view.trailingAnchor.constraint(equalTo: window.trailingAnchor).isActive = true

        // Animate the toast in.
        UIView.animate(withDuration: UI.duration(transitionDuration)) {
            viewController.view.layer.opacity = 1
        }

        // Dismiss the toast after 3 seconds.
        Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { _ in
            Task { @MainActor in
                hide(viewController.view)
            }
        }
    }

    // MARK: Private Methods

    /// Calculates the additionalSafeAreaInsets based on the presence of a TabBar.
    ///
    /// - Parameter parentViewController: The parent view controller that the toast is shown in.
    ///
    private static func getSafeArea(from parentViewController: UIViewController) -> UIEdgeInsets {
        let tabBarController = parentViewController.children
            .compactMap { $0 as? UITabBarController }
            .first

        if let tabBar = tabBarController?.tabBar,
           let selected = tabBarController?.selectedViewController,
           let topViewController = (selected as? UINavigationController)?.topViewController,
           !topViewController.hidesBottomBarWhenPushed {
            return UIEdgeInsets(top: 0, left: 0, bottom: tabBar.bounds.height, right: 0)
        }
        return parentViewController.view.safeAreaInsets
    }

    /// Hides the toast from showing over the specified view controller
    ///
    /// - Parameter view: The toast view to hide.
    ///
    private static func hide(_ view: UIView) {
        UIView.animate(withDuration: UI.duration(transitionDuration)) {
            view.layer.opacity = 0
        } completion: { _ in
            view.removeFromSuperview()
        }
    }
}
