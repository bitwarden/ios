import BitwardenKit
import BitwardenKitMocks
import SwiftUI
import XCTest

class DebugMenuCoordinatorTests: BitwardenTestCase {
    // MARK: Properties

    var configService: MockConfigService!
    var delegate: MockDebugMenuCoordinatorDelegate!
    var stackNavigator: MockStackNavigator!
    var subject: DebugMenuCoordinator!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        configService = MockConfigService()
        delegate = MockDebugMenuCoordinatorDelegate()
        stackNavigator = MockStackNavigator()

        subject = DebugMenuCoordinator(
            delegate: delegate,
            services: ServiceContainer.withMocks(
                configService: configService,
            ),
            stackNavigator: stackNavigator,
        )
    }

    override func tearDown() {
        super.tearDown()

        configService = nil
        delegate = nil
        stackNavigator = nil
        subject = nil
    }

    // MARK: Tests

    /// `navigate(to:)` with `.dismiss` dismisses the view.
    @MainActor
    func test_navigate_dismiss() throws {
        subject.navigate(to: .dismiss)

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .dismissedWithCompletionHandler)
        XCTAssertTrue(delegate.didDismissDebugMenuCalled)
    }

    /// `start()` correctly shows the `DebugMenuView`.
    @MainActor
    func test_start() {
        subject.start()

        XCTAssertTrue(stackNavigator.actions.last?.view is DebugMenuView)
    }
}
