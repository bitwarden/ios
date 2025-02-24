import SwiftUI
import UIKit

enum ToastDisplayHelper {
    // MARK: Type Properties

    /// The duration in seconds of the show and hide transitions.
    static let transitionDuration: TimeInterval = 0.2

    /// A value that is used to identify the toast within the view hierarchy in
    /// order to remove it.
    static let toastTag = 2000

    // MARK: Type Methods

    /// Shows the toast over the specified view controller.
    ///
    /// - Parameters:
    ///   - parentViewController: The parent view controller that the toast should be shown above.
    ///   - toast: The toast to display.
    ///   - duration: The number of seconds the toast should display for.
    ///
    static func show(in parentViewController: UIViewController, toast: Toast, duration: TimeInterval = 3) {
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
        let bottomPadding = window.safeAreaInsets.bottom + getSafeArea(from: parentViewController).bottom + 14
        viewController.view.translatesAutoresizingMaskIntoConstraints = false
        viewController.view.bottomAnchor.constraint(equalTo: window.bottomAnchor, constant: -bottomPadding)
            .isActive = true
        viewController.view.centerXAnchor.constraint(equalTo: window.centerXAnchor).isActive = true

        // Animate the toast in.
        UIView.animate(withDuration: UI.duration(transitionDuration)) {
            viewController.view.layer.opacity = 1
        }

        // Dismiss the toast after 3 seconds.
        Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { _ in
            hide(from: parentViewController)
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
            let height = tabBar.bounds.height - tabBar.safeAreaInsets.bottom
            return UIEdgeInsets(top: 0, left: 0, bottom: height, right: 0)
        }
        return .zero
    }

    /// Hides the toast from showing over the specified view controller
    ///
    /// - Parameter parentViewController: The parent view controller that the toast is shown in.
    ///
    private static func hide(from parentViewController: UIViewController) {
        guard let view = parentViewController.view.window?.viewWithTag(toastTag) else { return }

        UIView.animate(withDuration: UI.duration(transitionDuration)) {
            view.layer.opacity = 0
        } completion: { _ in
            view.removeFromSuperview()
        }
    }
}
