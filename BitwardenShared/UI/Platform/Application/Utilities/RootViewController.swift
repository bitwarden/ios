import UIKit

/// The root view controller for the app.
///
/// This view controller is the entry point into the application, and all screens are presented within this view
/// controller.
///
public class RootViewController: UIViewController {
    /// The app's theme.
    public var appTheme: AppTheme = .default

    // MARK: Properties

    /// The child view controller currently being displayed within this root view controller.
    ///
    /// Setting this value will remove the previously displayed view controller and immediately replace it with
    /// the new value. This replacement is not animated.
    ///
    public var childViewController: UIViewController? {
        didSet {
            dismiss(animated: false)

            if let fromViewController = oldValue {
                fromViewController.willMove(toParent: nil)
                fromViewController.view.removeFromSuperview()
                fromViewController.removeFromParent()
            }

            if let toViewController = childViewController {
                addChild(toViewController)
                view.addConstrained(subview: toViewController.view)
                toViewController.didMove(toParent: self)
            }
        }
    }
}
