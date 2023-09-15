import SwiftUI
import XCTest

@testable import BitwardenShared

// MARK: - StackNavigatorTests

@MainActor
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

    /// `present(_:animated:)` presents the hosted view.
    func test_present() {
        subject.present(EmptyView(), animated: false)
        XCTAssertTrue(subject.presentedViewController is UIHostingController<EmptyView>)
    }

    /// `present(_:animated:)` presents the hosted view.
    func test_present_overFullscreen() {
        subject.present(EmptyView(), animated: false, overFullscreen: true)
        XCTAssertEqual(subject.presentedViewController?.modalPresentationStyle, .overFullScreen)
        XCTAssertEqual(subject.presentedViewController?.view.backgroundColor, .clear)
        XCTAssertTrue(subject.presentedViewController is UIHostingController<EmptyView>)
    }

    /// `present(_:animated:)` presents the hosted view on existing presented views.
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
    func test_dismiss() {
        subject.present(EmptyView(), animated: false)
        subject.dismiss(animated: false)
        waitFor(subject.presentedViewController == nil)
    }

    /// `push(_:animated:)` pushes the hosted view.
    func test_push() {
        subject.push(EmptyView(), animated: false)
        XCTAssertTrue(subject.topViewController is UIHostingController<EmptyView>)
    }

    /// `pop(animated:)` pops the hosted view.
    func test_pop() {
        subject.push(EmptyView(), animated: false)
        subject.push(EmptyView(), animated: false)
        let viewController = subject.pop(animated: false)
        XCTAssertTrue(viewController is UIHostingController<EmptyView>)
        XCTAssertEqual(subject.viewControllers.count, 1)
        XCTAssertTrue(subject.topViewController is UIHostingController<EmptyView>)
    }

    /// `popToRoot(animated:)` pops to the root hosted view.
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
    func test_replace() {
        subject.push(EmptyView(), animated: false)
        subject.replace(Text("replaced"), animated: false)
        XCTAssertEqual(subject.viewControllers.count, 1)
        XCTAssertTrue(subject.topViewController is UIHostingController<Text>)
    }
}
