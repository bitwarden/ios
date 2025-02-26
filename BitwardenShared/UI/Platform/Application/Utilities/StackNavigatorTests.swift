import SwiftUI
import XCTest

@testable import BitwardenShared

// MARK: - StackNavigatorTests

class StackNavigatorTests: BitwardenTestCase {
    // MARK: Properties

    var subject: UINavigationController!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        subject = UINavigationController()
        setKeyWindowRoot(viewController: subject)
    }

    // MARK: Tests

    /// `isEmpty` returns whether the navigator's stack is empty.
    @MainActor
    func test_isEmpty() {
        XCTAssertTrue(subject.isEmpty)

        subject.pushViewController(UIViewController(), animated: false)
        XCTAssertFalse(subject.isEmpty)

        subject.viewControllers = []
        XCTAssertTrue(subject.isEmpty)
    }

    /// `isPresenting` returns true when a view is being presented on this navigator.
    @MainActor
    func test_isPresenting() {
        XCTAssertFalse(subject.isPresenting)

        subject.present(EmptyView(), animated: false)
        XCTAssertTrue(subject.isPresenting)
    }

    /// `present(_:animated:)` presents the hosted view.
    @MainActor
    func test_present() {
        subject.present(EmptyView(), animated: false)
        XCTAssertTrue(subject.presentedViewController is UIHostingController<EmptyView>)
    }

    /// `present(_:animated:)` presents the hosted view.
    @MainActor
    func test_present_overFullscreen() {
        subject.present(EmptyView(), animated: false, overFullscreen: true)
        XCTAssertEqual(subject.presentedViewController?.modalPresentationStyle, .overFullScreen)
        XCTAssertEqual(subject.presentedViewController?.view.backgroundColor, .clear)
        XCTAssertTrue(subject.presentedViewController is UIHostingController<EmptyView>)
    }

    /// `present(_:animated:)` presents the hosted view on existing presented views.
    @MainActor
    func test_present_onPresentedView() {
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
    @MainActor
    func test_dismiss() {
        subject.present(EmptyView(), animated: false)
        subject.dismiss(animated: false)
        waitFor(subject.presentedViewController == nil)
    }

    /// `dismiss(animated:)` dismisses the hosted view and executes a block of code
    /// when dismissing is complete.
    @MainActor
    func test_dismiss_completion() {
        var isBlockExecuted = false

        subject.present(EmptyView(), animated: false)
        subject.dismiss {
            isBlockExecuted = true
        }
        waitFor(subject.presentedViewController == nil)
        XCTAssertTrue(isBlockExecuted)
    }

    /// `push(_:animated:)` pushes the hosted view.
    @MainActor
    func test_push_view() {
        subject.push(EmptyView(), animated: false)
        XCTAssertTrue(subject.topViewController is UIHostingController<EmptyView>)
    }

    /// `push(_:animated:hidesBottomBar:)` pushes the hosted view and hides the bottom bar.
    @MainActor
    func test_push_view_hidesBottomBar_true() throws {
        subject.push(EmptyView(), animated: false, hidesBottomBar: true)
        let viewController = try XCTUnwrap(subject.topViewController)
        XCTAssertTrue(viewController is UIHostingController<EmptyView>)
        XCTAssertTrue(viewController.hidesBottomBarWhenPushed)
    }

    /// `push(_:animated:)` pushes the view controller.
    @MainActor
    func test_push_viewController() {
        let viewController = UIViewController()
        subject.push(viewController, animated: false)
        XCTAssertIdentical(subject.topViewController, viewController)
    }

    /// `pop(animated:)` pops the hosted view.
    @MainActor
    func test_pop() {
        subject.push(EmptyView(), animated: false)
        subject.push(EmptyView(), animated: false)
        let viewController = subject.pop(animated: false)
        XCTAssertTrue(viewController is UIHostingController<EmptyView>)
        XCTAssertEqual(subject.viewControllers.count, 1)
        XCTAssertTrue(subject.topViewController is UIHostingController<EmptyView>)
    }

    /// `popToRoot(animated:)` pops to the root hosted view.
    @MainActor
    func test_popToRoot() {
        subject.push(EmptyView(), animated: false)
        subject.push(EmptyView(), animated: false)
        subject.push(EmptyView(), animated: false)
        let viewControllers = subject.popToRoot(animated: false)
        XCTAssertEqual(viewControllers.count, 2)
        XCTAssertEqual(subject.viewControllers.count, 1)
        XCTAssertTrue(subject.topViewController is UIHostingController<EmptyView>)
    }

    /// `replace(_:animated:)` replaces the hosted view.
    @MainActor
    func test_replace() {
        subject.push(EmptyView(), animated: false)
        subject.replace(Text("replaced"), animated: false)
        XCTAssertEqual(subject.viewControllers.count, 1)
        XCTAssertTrue(subject.topViewController is UIHostingController<Text>)
    }
}
