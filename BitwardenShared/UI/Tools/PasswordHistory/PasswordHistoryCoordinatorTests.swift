import SwiftUI
import XCTest

@testable import BitwardenShared

class PasswordHistoryCoordinatorTests: BitwardenTestCase {
    // MARK: Properties

    var stackNavigator: MockStackNavigator!
    var subject: PasswordHistoryCoordinator!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        stackNavigator = MockStackNavigator()

        subject = PasswordHistoryCoordinator(
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

    /// `navigate(to:)` with `.dismiss` dismisses the top most view presented by the stack
    /// navigator.
    func test_navigate_dismiss() throws {
        subject.navigate(to: .dismiss)

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .dismissed)
    }

    /// `navigate(to:)` with `.passwordHistoryList(_)` displays the password history list view.
    func test_navigate_passwordHistoryList() throws {
        subject.navigate(to: .passwordHistoryList(.generator))

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .replaced)
        XCTAssertTrue(action.view is PasswordHistoryListView)
    }

    /// `start()` has no effect.
    func test_start() {
        subject.start()

        XCTAssertTrue(stackNavigator.actions.isEmpty)
    }
}
