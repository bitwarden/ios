import XCTest

@testable import BitwardenShared

// MARK: - MockUIViewController

class MockUIViewController: UIViewController {
    var presentCalled = false
    var presentedView: UIViewController?

    override func present(
        _ viewControllerToPresent: UIViewController,
        animated _: Bool,
        completion _: (() -> Void)? = nil
    ) {
        presentCalled = true
        presentedView = viewControllerToPresent
    }
}
