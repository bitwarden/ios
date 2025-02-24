import XCTest

@testable import AuthenticatorShared

// MARK: - AlertPresentableTests

class AlertPresentableTests: AuthenticatorTestCase {
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
}

class AlertPresentableSubject: AlertPresentable {
    var rootViewController: UIViewController?
}
