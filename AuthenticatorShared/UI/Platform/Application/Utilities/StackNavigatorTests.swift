import SwiftUI
import XCTest

@testable import AuthenticatorShared

@MainActor
class StackNavigatorTests: AuthenticatorTestCase {
    var subject: UINavigationController!

    override func setUp() {
        super.setUp()
        subject = UINavigationController()
        setKeyWindowRoot(viewController: subject)
    }

    /// `present(_:animated:)` presents the hosted view.
    func testPresent() {
        subject.present(EmptyView(), animated: false)
        XCTAssertTrue(subject.presentedViewController is UIHostingController<EmptyView>)
    }

    /// `present(_:animated:)` presents the hosted view on existing presented views.
    func testPresentOnPresentedView() {
        subject.present(EmptyView(), animated: false)
        subject.present(ScrollView<EmptyView> {}, animated: false)
        XCTAssertTrue(subject.presentedViewController is UIHostingController<EmptyView>)
        waitFor(subject.presentedViewController?.presentedViewController != nil)
        XCTAssertTrue(
            subject.presentedViewController?.presentedViewController
                is UIHostingController<ScrollView<EmptyView>>
        )
    }

    /// `dismiss(animated:)` dismisses the hosted view.
    func testDismiss() {
        subject.present(EmptyView(), animated: false)
        subject.dismiss(animated: false)
        waitFor(subject.presentedViewController == nil)
    }

    /// `push(_:animated:)` pushes the hosted view.
    func testPush() {
        subject.push(EmptyView(), animated: false)
        XCTAssertTrue(subject.topViewController is UIHostingController<EmptyView>)
    }

    /// `pop(animated:)` pops the hosted view.
    func testPop() {
        subject.push(EmptyView(), animated: false)
        subject.push(EmptyView(), animated: false)
        subject.pop(animated: false)
        XCTAssertEqual(subject.viewControllers.count, 1)
        XCTAssertTrue(subject.topViewController is UIHostingController<EmptyView>)
    }

    /// `replace(_:animated:)` replaces the hosted view.
    func testReplace() {
        subject.push(EmptyView(), animated: false)
        subject.replace(Text("replaced"), animated: false)
        XCTAssertEqual(subject.viewControllers.count, 1)
        XCTAssertTrue(subject.topViewController is UIHostingController<Text>)
    }
}
