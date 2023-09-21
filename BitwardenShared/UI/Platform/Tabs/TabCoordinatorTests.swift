import SwiftUI
import XCTest

@testable import BitwardenShared

// MARK: - TabCoordinatorTests

class TabCoordinatorTests: BitwardenTestCase {
    // MARK: Properties

    var rootNavigator: MockRootNavigator!
    var subject: TabCoordinator!
    var tabNavigator: MockTabNavigator!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        rootNavigator = MockRootNavigator()
        tabNavigator = MockTabNavigator()
        subject = TabCoordinator(
            rootNavigator: rootNavigator,
            tabNavigator: tabNavigator
        )
    }

    override func tearDown() {
        super.tearDown()
        rootNavigator = nil
        subject = nil
        tabNavigator = nil
    }

    // MARK: Tests

    /// `navigate(to:)` with `.generator` sets the correct selected index on tab navigator.
    func test_navigate_generator() {
        subject.navigate(to: .generator)
        XCTAssertEqual(tabNavigator.selectedIndex, 2)
    }

    /// `navigate(to:)` with `.send` sets the correct selected index on tab navigator.
    func test_navigate_send() {
        subject.navigate(to: .send)
        XCTAssertEqual(tabNavigator.selectedIndex, 1)
    }

    /// `navigate(to:)` with `.settings` sets the correct selected index on tab navigator.
    func test_navigate_settings() {
        subject.navigate(to: .settings)
        XCTAssertEqual(tabNavigator.selectedIndex, 3)
    }

    /// `navigate(to:)` with `.vault` sets the correct selected index on tab navigator.
    func test_navigate_vault() {
        subject.navigate(to: .vault)
        XCTAssertEqual(tabNavigator.selectedIndex, 0)
    }

    /// `rootNavigator` uses a weak reference and does not retain a value once the root navigator has been erased.
    func test_rootNavigator_resetWeakReference() {
        var rootNavigator: MockRootNavigator? = MockRootNavigator()
        subject = TabCoordinator(
            rootNavigator: rootNavigator!,
            tabNavigator: tabNavigator
        )
        XCTAssertNotNil(subject.rootNavigator)

        rootNavigator = nil
        XCTAssertNil(subject.rootNavigator)
    }

    /// `start()` presents the tab navigator within the root navigator and starts the child-coordinators.
    func test_start() {
        subject.start()
        XCTAssertIdentical(rootNavigator.navigatorShown, tabNavigator)

        // Placeholder assertion until the vault screen is added: BIT-218
        XCTAssertTrue(tabNavigator.navigators[0] is StackNavigator)

        // Placeholder assertion until the send screen is added: BIT-249
        XCTAssertTrue(tabNavigator.navigators[1] is StackNavigator)

        // Placeholder assertion until the generator screen is added: BIT-331
        XCTAssertTrue(tabNavigator.navigators[2] is StackNavigator)

        // Placeholder assertion until the settings screen is added: BIT-150
        XCTAssertTrue(tabNavigator.navigators[3] is StackNavigator)
    }
}
