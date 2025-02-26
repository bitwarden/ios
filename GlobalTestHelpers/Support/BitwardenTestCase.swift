import BitwardenShared
import TestHelpers
import XCTest

open class BitwardenTestCase: BaseBitwardenTestCase {
    @MainActor
    override open class func setUp() {
        // Apply default appearances for snapshot tests.
        UI.applyDefaultAppearances()
    }

    /// Executes any logic that should be applied before each test runs.
    ///
    @MainActor
    override open func setUp() {
        super.setUp()
        UI.animated = false
        UI.sizeCategory = .large
    }

    /// Executes any logic that should be applied after each test runs.
    ///
    override open func tearDown() {
        super.tearDown()
        UI.animated = false
    }

    /// Nests a `UIView` within a root view controller in the test window. Allows testing
    /// changes to the view that require the view to exist within a window or are dependent on safe
    /// area layouts.
    ///
    /// This is currently in the `BitwardenShared` copy of `BitwardenTestCase`
    /// because it relies on `UIView.addConstrained(:)`, which is still in `BitwardenShared`.
    ///
    /// - Parameters:
    ///     - view: The `UIView` to add to a root view controller.
    ///
    open func setKeyWindowRoot(view: UIView) {
        let viewController = UIViewController()
        viewController.view.addConstrained(subview: view)
        window.rootViewController = viewController
        window.makeKeyAndVisible()
    }
}
