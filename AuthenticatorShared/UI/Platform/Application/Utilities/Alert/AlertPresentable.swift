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
}

public extension AlertPresentable {
    /// Presents a `UIAlertController` created from the `Alert` on the provided `rootViewController`.
    ///
    /// - Parameter alert: The `Alert` used to create a `UIAlertController` to present.
    ///
    func present(_ alert: Alert) {
        let alertController = alert.createAlertController()
        guard let parent = rootViewController?.topmostViewController() else { return }

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
