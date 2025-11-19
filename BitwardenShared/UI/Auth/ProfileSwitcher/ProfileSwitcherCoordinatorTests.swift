import BitwardenKitMocks
import TestHelpers
import XCTest

@testable import BitwardenShared

// MARK: - ProfileSwitcherCoordinatorTests

class ProfileSwitcherCoordinatorTests: BitwardenTestCase {
    // MARK: Properties

    var handler: MockProfileSwitcherHandler!
    var stackNavigator: MockStackNavigator!
    var subject: ProfileSwitcherCoordinator!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        handler = MockProfileSwitcherHandler()
        stackNavigator = MockStackNavigator()

        subject = ProfileSwitcherCoordinator(
            handler: handler,
            services: ServiceContainer.withMocks(),
            stackNavigator: stackNavigator,
        )
    }

    override func tearDown() {
        super.tearDown()
        stackNavigator = nil
        subject = nil
    }

    // MARK: Tests

    /// `navigate(to: .dismiss)` dismisses the profile switcher.
    @MainActor
    func test_navigate_dismiss() throws {
        subject.navigate(to: .dismiss)

        XCTAssertEqual(stackNavigator.actions.last?.type, .dismissed)
    }

    /// `navigate(to: .open)` opens the profile switcher.
    @MainActor
    func test_navigate_open() throws {
        handler.profileSwitcherState = .empty()

        subject.navigate(to: .open)

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .replaced)
        XCTAssertTrue(action.view is ProfileSwitcherSheet)
    }
}
