import UIKit

// MARK: - ViewLoggingNavigationController

/// A `UINavigationController` which logs when views appear and are dismissed as a user is
/// navigating throughout the app.
///
/// For this to work throughout the application, this needs to be consistently used in place of
/// `UINavigationController` *or* the `delegate` and `presentationController?.delegate` need to be
/// passed from an existing navigation controller to any newly created `UINavigationController`.
///
public class ViewLoggingNavigationController: UINavigationController,
    UINavigationControllerDelegate,
    UIAdaptivePresentationControllerDelegate {
    // MARK: Properties

    /// The logger instance used to log when views appear and are dismissed.
    let logger: BitwardenLogger

    // MARK: Initialization

    /// Initialize a `ViewLoggingNavigationController`.
    ///
    /// - Parameter logger: The logger instance used to log when views appear and are dismissed.
    ///
    public init(logger: BitwardenLogger) {
        self.logger = logger
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: View Lifecycle

    override public func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        presentationController?.delegate = self
    }

    // MARK: UINavigationController

    override public func dismiss(animated: Bool, completion: (() -> Void)? = nil) {
        super.dismiss(animated: animated, completion: completion)
        logger.log("[Navigation] View dismissed: \(resolveLoggingViewName(for: self))")
    }

    // MARK: UINavigationControllerDelegate

    public func navigationController(
        _ navigationController: UINavigationController,
        didShow viewController: UIViewController,
        animated: Bool,
    ) {
        logger.log("[Navigation] View appeared: \(resolveLoggingViewName(for: viewController))")
    }

    // MARK: UIAdaptivePresentationControllerDelegate

    public func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        let viewController = presentationController.presentedViewController
        logger.log("[Navigation] View dismissed interactively: \(resolveLoggingViewName(for: viewController))")
    }

    // MARK: Private

    /// Returns the view's name for the purpose of logging. This attempts to unwrap
    /// `UIHostingController`s and `UINavigationController`s to log a more descriptive name of the
    /// view contained within these container view controllers.
    ///
    /// - Parameter viewController: The view controller for which to determine the name of the view
    ///     for logging purposes.
    /// - Returns: The view's name for logging purposes.
    ///
    private func resolveLoggingViewName(for viewController: UIViewController) -> String {
        let viewType = String(describing: type(of: viewController))
        if viewType.contains("HostingController") {
            guard let start = viewType.firstIndex(of: "<"),
                  let end = viewType.firstIndex(of: ">"),
                  start < end else {
                return viewType
            }
            let innerType = viewType[viewType.index(after: start) ..< end]
            return String(innerType)
        } else if let navigationController = viewController as? UINavigationController,
                  let visibleViewController = navigationController.visibleViewController {
            return resolveLoggingViewName(for: visibleViewController)
        } else {
            return viewType
        }
    }
}
