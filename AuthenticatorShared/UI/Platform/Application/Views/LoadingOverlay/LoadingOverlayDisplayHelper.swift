import SwiftUI
import UIKit

/// A helper to configure showing and hiding the `LoadingOverlayView` within a view controller.
///
enum LoadingOverlayDisplayHelper {
    // MARK: Type Properties

    /// The duration in seconds of the show and hide transitions.
    static let transitionDuration: TimeInterval = 0.2

    /// A value that is used to identify the loading overlay view within the view hierarchy in
    /// order to remove it.
    static let overlayViewTag = 1000

    // MARK: Type Methods

    /// Shows the loading overlay view as a full-screen view over the specified view controller.
    ///
    /// - Parameters:
    ///   - parentViewController: The parent view controller that the overlay should be shown above.
    ///   - state: State used to configure the display of the loading overlay view.
    ///
    static func show(in parentViewController: UIViewController, state: LoadingOverlayState) {
        guard parentViewController.view.window?.viewWithTag(overlayViewTag) == nil,
              let window = parentViewController.view.window
        else {
            return
        }

        let viewController = UIHostingController(rootView: LoadingOverlayView(state: state))
        viewController.view.layer.backgroundColor = nil
        viewController.view.layer.opacity = 0
        viewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        viewController.view.frame = window.frame
        viewController.view.tag = overlayViewTag
        window.addSubview(viewController.view)

        UIView.animate(withDuration: UI.duration(transitionDuration)) {
            viewController.view.layer.opacity = 1
        }
    }

    /// Hides the loading overlay view from showing over the specified view controller
    ///
    /// - Parameter parentViewController: The parent view controller that the overlay is shown above.
    ///
    static func hide(from parentViewController: UIViewController) {
        guard let view = parentViewController.view.window?.viewWithTag(overlayViewTag) else { return }

        UIView.animate(withDuration: UI.duration(transitionDuration)) {
            view.layer.opacity = 0
        } completion: { _ in
            view.removeFromSuperview()
        }
    }
}
