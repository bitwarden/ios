import BitwardenKit
import BitwardenKitMocks
import SwiftUI
import XCTest

// MARK: - StackNavigatorTests

class StackNavigatorHostedTests: BitwardenTestCase {
    // MARK: Properties

    var subject: UINavigationController!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        subject = UINavigationController()
        setKeyWindowRoot(viewController: subject)
    }

    // MARK: Tests

    /// `present(_:animated:)` presents the hosted view on existing presented views.
    /// This is in `BitwardenSharedTests` instead of `BitwardenKitTests` because it requires a host app,
    /// due to the fact that the implementation of `StackNavigator` creates a `UIHostingController`,
    /// so we cannot mock it without significantly more rigamarole, which seems excessive for one test.
    @MainActor
    func test_present_onPresentedView() {
        subject.present(EmptyView(), animated: false, embedInNavigationController: false)
        subject.present(ScrollView<EmptyView> {}, animated: false, embedInNavigationController: false)
        XCTAssertTrue(subject.presentedViewController is UIHostingController<EmptyView>)
        waitFor(subject.presentedViewController?.presentedViewController != nil)
        XCTAssertTrue(
            subject.presentedViewController?.presentedViewController
                is UIHostingController<ScrollView<EmptyView>>,
        )
    }
}
