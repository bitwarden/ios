import BitwardenKitMocks
import SwiftUI
import XCTest

@testable import BitwardenKit

class ViewLoggingNavigationControllerTests: BitwardenTestCase {
    // MARK: Properties

    var logger: MockBitwardenLogger!
    var subject: ViewLoggingNavigationController!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        logger = MockBitwardenLogger()

        subject = ViewLoggingNavigationController(logger: logger)
        setKeyWindowRoot(viewController: subject)
    }

    override func tearDown() {
        super.tearDown()

        logger = nil
        subject = nil
    }

    // MARK: Tests

    /// `viewDidLoad()` sets the navigation and presentation controller delegates.
    func test_viewDidLoad_setsDelegates() {
        XCTAssertIdentical(subject.delegate, subject)
        XCTAssertIdentical(subject.presentationController?.delegate, subject)
    }

    /// `dismiss(animated:completion:)` logs the dismissed view.
    @MainActor
    func test_dismiss() {
        let presentedViewController = UIHostingController(rootView: EmptyView())
        subject.present(presentedViewController, animated: false)
        subject.dismiss(animated: false)
        XCTAssertEqual(logger.logs, ["[Navigation] View dismissed: EmptyView"])
    }

    /// `navigationController(_:didShow:animated:)` logs the shown hosting controller's view.
    @MainActor
    func test_navigationControllerDidShow_hostingController() {
        subject.navigationController(
            subject,
            didShow: UIHostingController(rootView: EmptyView()),
            animated: false,
        )
        XCTAssertEqual(logger.logs, ["[Navigation] View appeared: EmptyView"])
    }

    /// `navigationController(_:didShow:animated:)` logs the shown view when the view is a hosting
    /// controller that isn't a generic UIHostingController.
    @MainActor
    func test_navigationControllerDidShow_hostingControllerNotGeneric() {
        class HostingController: UIViewController {}
        subject.navigationController(subject, didShow: HostingController(), animated: false)
        XCTAssertEqual(logger.logs, ["[Navigation] View appeared: HostingController"])
    }

    /// `navigationController(_:didShow:animated:)` logs the shown navigation controller's view.
    @MainActor
    func test_navigationControllerDidShow_navigationController() {
        let viewController = UINavigationController(rootViewController: UIHostingController(rootView: EmptyView()))
        subject.navigationController(subject, didShow: viewController, animated: false)
        XCTAssertEqual(logger.logs, ["[Navigation] View appeared: EmptyView"])
    }

    /// `navigationController(_:didShow:animated:)` logs the shown view controller.
    @MainActor
    func test_navigationControllerDidShow_viewController() {
        class TestViewController: UIViewController {}
        subject.navigationController(subject, didShow: TestViewController(), animated: false)
        XCTAssertEqual(logger.logs, ["[Navigation] View appeared: TestViewController"])
    }

    /// `presentationControllerDidDismiss(_:)` logs the interactively dismissed view.
    @MainActor
    func test_presentationControllerDidDismiss() {
        let presentationController = UIPresentationController(
            presentedViewController: UIHostingController(rootView: EmptyView()),
            presenting: subject,
        )
        subject.presentationControllerDidDismiss(presentationController)
        XCTAssertEqual(logger.logs, ["[Navigation] View dismissed interactively: EmptyView"])
    }
}
