import SwiftUI
import XCTest

@testable import BitwardenShared

class SendCoordinatorTests: BitwardenTestCase {
    // MARK: Properties

    var stackNavigator: MockStackNavigator!
    var subject: SendCoordinator!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        stackNavigator = MockStackNavigator()
        subject = SendCoordinator(
            services: ServiceContainer.withMocks(),
            stackNavigator: stackNavigator
        )
    }

    override func tearDown() {
        super.tearDown()
        stackNavigator = nil
        subject = nil
    }

    // MARK: Tests

    /// `navigate(to:)` with `.addItem` presents the add send item screen.
    func test_navigateTo_addItem() throws {
        subject.navigate(to: .addItem)

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .presented)
        let navigationController = try XCTUnwrap(action.view as? UINavigationController)
        XCTAssertTrue(navigationController.viewControllers.first is UIHostingController<AddEditSendItemView>)
    }

    /// `navigate(to:)` with `.dismiss` dismisses the current modally presented screen.
    func test_navigateTo_dismiss() throws {
        subject.navigate(to: .dismiss)

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .dismissed)
    }

    /// `navigate(to:)` with `.list` replaces the stack navigator's current stack with the send list
    /// screen.
    func test_navigateTo_list() throws {
        subject.navigate(to: .list)

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .replaced)
        XCTAssertTrue(action.view is SendListView)
    }

    /// `start()` initializes the coordinator's state correctly.
    func test_start() throws {
        subject.start()

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .replaced)
        XCTAssertTrue(action.view is SendListView)
    }
}
