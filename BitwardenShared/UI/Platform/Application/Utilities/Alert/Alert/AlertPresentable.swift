import OSLog
import UIKit

// MARK: - AlertPresentable

/// Protocol for creating and presenting a `UIAlertController` from an `Alert`.
///
@MainActor
public protocol AlertPresentable {
    /// The root view controller that the alert should be presented on.
    var rootViewController: UIViewController? { get }

    /// Presents a `UIAlertController` created from the `Alert` on the provided `rootViewController`.
    ///
    /// - Parameter alert: The `Alert` used to create a `UIAlertController` to present.
    ///
    func present(_ alert: Alert)

    /// Presents a `UIAlertController` created from the `Alert` on the provided `rootViewController`.
    ///
    /// - Parameters:
    ///   - alert: The `Alert` used to create a `UIAlertController` to present.
    ///   - onDismissed: An optional closure that is called when the alert is dismissed.
    ///
    func present(_ alert: Alert, onDismissed: (() -> Void)?)
}

public extension AlertPresentable {
    /// Presents a `UIAlertController` created from the `Alert` on the provided `rootViewController`.
    ///
    /// - Parameter alert: The `Alert` used to create a `UIAlertController` to present.
    ///
    func present(_ alert: Alert) {
        present(alert, onDismissed: nil)
    }

    /// Presents a `UIAlertController` created from the `Alert` on the provided `rootViewController`.
    ///
    /// - Parameters:
    ///   - alert: The `Alert` used to create a `UIAlertController` to present.
    ///   - onDismissed: An optional closure that is called when the alert is dismissed.
    ///
    func present(_ alert: Alert, onDismissed: (() -> Void)?) {
        guard let parent = rootViewController?.topmostViewController() else { return }

        // Prevent presenting alerts on alerts.
        guard !(parent is UIAlertController) else {
            Logger.application.error("⛔️ Error: attempted to present an alert on top of another alert!")
            return
        }

        let alertController = alert.createAlertController(onDismissed: onDismissed)
        if alert.preferredStyle == .actionSheet {
            // iPadOS requires an anchor for action sheets. This solution keeps the iPad app from crashing, and centers
            // the presentation of the action sheet.
            alertController.popoverPresentationController?.sourceView = parent.view
            alertController.popoverPresentationController?.sourceRect = CGRect(
                x: parent.view.bounds.midX,
                y: parent.view.bounds.midY,
                width: 0,
                height: 0
            )
            alertController.popoverPresentationController?.permittedArrowDirections = []
        }

        parent.present(alertController, animated: UI.animated)
    }
}

extension UIWindow: AlertPresentable {}
