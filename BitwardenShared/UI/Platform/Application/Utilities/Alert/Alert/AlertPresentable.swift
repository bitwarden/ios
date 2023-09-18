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
        let parent = rootViewController?.topmostViewController()
        parent?.present(alertController, animated: UI.animated)
    }
}

extension UIWindow: AlertPresentable {}
