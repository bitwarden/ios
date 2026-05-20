import BitwardenKit
import BitwardenKitMocks
import XCTest

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - GlobalModalCoordinatorTests

class GlobalModalCoordinatorTests: BitwardenTestCase {
    // MARK: Properties

    var stackNavigator: MockStackNavigator!
    var subject: GlobalModalCoordinator!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        stackNavigator = MockStackNavigator()
        subject = GlobalModalCoordinator(
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

    /// `navigate(to:)` with `.dismissWithAction(nil)` dismisses the view without calling an action.
    @MainActor
    func test_navigate_dismissWithAction_nilAction() async throws {
        subject.navigate(to: .dismissWithAction(nil))

        try await waitForAsync { self.stackNavigator.actions.last?.type == .dismissedWithCompletionHandler }

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .dismissedWithCompletionHandler)
    }

    /// `navigate(to:)` with `.dismissWithAction(_)` dismisses the view and calls the dismiss action.
    @MainActor
    func test_navigate_dismissWithAction_withAction() async throws {
        var actionCalled = false
        let dismissAction = DismissAction { actionCalled = true }

        subject.navigate(to: .dismissWithAction(dismissAction))

        try await waitForAsync { actionCalled }

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .dismissedWithCompletionHandler)
        XCTAssertTrue(actionCalled)
    }

    /// `navigate(to:)` with `.syncWithBrowser` replaces the stack with the sync with browser view.
    @MainActor
    func test_navigate_syncWithBrowser() throws {
        subject.navigate(to: .syncWithBrowser(vaultUrl: "https://example.com"))

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .replaced)
        XCTAssertTrue(action.view is SyncWithBrowserView)
    }
}
