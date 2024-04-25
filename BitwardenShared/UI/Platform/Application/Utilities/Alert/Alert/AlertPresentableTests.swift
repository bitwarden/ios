import XCTest

@testable import BitwardenShared

// MARK: - AlertPresentableTests

class AlertPresentableTests: BitwardenTestCase {
    // MARK: Properties

    var rootViewController: UIViewController!
    var subject: AlertPresentableSubject!

    // MARK: Setup and Teardown

    override func setUp() {
        super.setUp()
        rootViewController = UIViewController()
        subject = AlertPresentableSubject()
        subject.rootViewController = rootViewController
        setKeyWindowRoot(viewController: rootViewController)
    }

    override func tearDown() {
        super.tearDown()
        rootViewController = nil
        subject = nil
    }

    // MARK: Tests

    /// `present(_:)` presents a `UIAlertController` on the root view controller.
    func test_present() {
        subject.present(Alert(title: "🍎", message: "🥝", preferredStyle: .alert))
        XCTAssertNotNil(rootViewController.presentedViewController as? UIAlertController)
    }

    /// `present(_:)` presents a `UIAlertController` and calls the `onDismissed` closure when it's been dismissed.
    func test_present_onDismissed() {
        var onDismissedCalled = false
        subject.present(Alert(title: "🍎", message: "🥝", preferredStyle: .alert)) {
            onDismissedCalled = true
        }
        rootViewController.dismiss(animated: false)
        waitFor(rootViewController.presentedViewController == nil)
        XCTAssertTrue(onDismissedCalled)
    }
}

class AlertPresentableSubject: AlertPresentable {
    var rootViewController: UIViewController?
}
