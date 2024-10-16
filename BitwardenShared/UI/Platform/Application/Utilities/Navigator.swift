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
}

extension Navigator {
    /// A flag indicating if this navigator is currently presenting a view modally.
    public var isPresenting: Bool {
        rootViewController?.presentedViewController != nil
    }

    /// Shows the loading overlay view.
    ///
    /// - Parameter state: The state for configuring the loading overlay.
    ///
    func showLoadingOverlay(_ state: LoadingOverlayState) {
        guard let rootViewController else { return }
        LoadingOverlayDisplayHelper.show(in: rootViewController.topmostViewController(), state: state)
    }

    /// Hides the loading overlay view.
    ///
    func hideLoadingOverlay() {
        guard let rootViewController else { return }
        LoadingOverlayDisplayHelper.hide(from: rootViewController.topmostViewController())
    }

    /// Shows the toast.
    ///
    /// - Parameter toast: The toast to display.
    ///
    func showToast(_ toast: Toast) {
        guard let rootViewController else { return }
        ToastDisplayHelper.show(in: rootViewController, toast: toast)
    }
}
