import BitwardenKit
import UIKit
import XCTest

// MARK: - MockUINavigationController

public class MockUINavigationController: UINavigationController {
    var pushViewControllerCalled = false
    var pushedViewController: UIViewController?
    var pushAnimated = false

    var popViewControllerCalled = false
    var popAnimated = false
    var poppedViewController: UIViewController?

    // MARK: - Initialization

    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    public init() {
        super.init(nibName: nil, bundle: nil)
    }

    public override init(rootViewController: UIViewController) {
        super.init(nibName: nil, bundle: nil)
        // Set viewControllers array directly to avoid hierarchy issues
        viewControllers = [rootViewController]
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    // MARK: - Overrides

    public override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        pushViewControllerCalled = true
        pushedViewController = viewController
        pushAnimated = animated

        // Add to view controllers array
        var controllers = viewControllers
        controllers.append(viewController)
        viewControllers = controllers

        // Simulate appearance transitions safely
        DispatchQueue.main.async {
            viewController.beginAppearanceTransition(true, animated: animated)
            viewController.endAppearanceTransition()
        }
    }

    @discardableResult
    public override func popViewController(animated: Bool) -> UIViewController? {
        popViewControllerCalled = true
        popAnimated = animated

        guard viewControllers.count > 1 else { return nil }

        var controllers = viewControllers
        let poppedVC = controllers.removeLast()
        poppedViewController = poppedVC
        viewControllers = controllers

        // Simulate appearance transitions safely
        DispatchQueue.main.async {
            poppedVC.beginAppearanceTransition(false, animated: animated)
            poppedVC.endAppearanceTransition()
        }

        return poppedVC
    }

    public func reset() {
        pushViewControllerCalled = false
        pushedViewController = nil
        pushAnimated = false

        popViewControllerCalled = false
        popAnimated = false
        poppedViewController = nil
    }
}
