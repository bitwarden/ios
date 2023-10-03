import SwiftUI

// MARK: - Navigator

/// A protocol for an object that can navigate between screens and show alerts.
///
@MainActor
public protocol Navigator: AlertPresentable, AnyObject {
    // MARK: Properties

    /// The root view controller of this `Navigator`.
    var rootViewController: UIViewController? { get }
}

extension Navigator {
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
}
