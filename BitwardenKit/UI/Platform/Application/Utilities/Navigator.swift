import SwiftUI

// MARK: - Navigator

/// A protocol for an object that can navigate between screens and show alerts.
///
@MainActor
public protocol Navigator: AlertPresentable, AnyObject {
    // MARK: Properties

    /// A flag indicating if this navigator is currently presenting a view modally.
    var isPresenting: Bool { get }

    /// The root view controller of this `Navigator`.
    var rootViewController: UIViewController? { get }

    // MARK: Methods

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
        animated: Bool,
        overFullscreen: Bool,
        onCompletion: (() -> Void)?,
    )
}

public extension Navigator {
    /// A flag indicating if this navigator is currently presenting a view modally.
    var isPresenting: Bool {
        rootViewController?.presentedViewController != nil
    }

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
        present(viewController, animated: animated, overFullscreen: overFullscreen, onCompletion: onCompletion)
    }

    /// Shows the loading overlay view.
    ///
    /// - Parameter state: The state for configuring the loading overlay.
    ///
    func showLoadingOverlay(_ state: LoadingOverlayState) {
        guard let rootViewController else { return }
        LoadingOverlayDisplayHelper.show(in: rootViewController, state: state)
    }

    /// Hides the loading overlay view.
    ///
    func hideLoadingOverlay() {
        guard let rootViewController else { return }
        LoadingOverlayDisplayHelper.hide(from: rootViewController)
    }

    /// Shows the toast.
    ///
    /// - Parameters:
    ///   - toast: The toast to display.
    ///   - additionalBottomPadding: Additional padding to apply to the bottom of the toast.
    ///
    func showToast(_ toast: Toast, additionalBottomPadding: CGFloat = 0) {
        guard let rootViewController else { return }
        ToastDisplayHelper.show(
            in: rootViewController,
            toast: toast,
            additionalBottomPadding: additionalBottomPadding,
        )
    }
}
