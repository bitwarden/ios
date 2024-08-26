import SwiftUI
import XCTest

@testable import BitwardenShared

class LoginRequestCoordinatorTests: BitwardenTestCase {
    // MARK: Properties

    var stackNavigator: MockStackNavigator!
    var subject: LoginRequestCoordinator!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        stackNavigator = MockStackNavigator()

        subject = LoginRequestCoordinator(
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

    /// `navigate(to:)` with `.dismiss` dismisses the view.
    @MainActor
    func test_navigate_dismiss() throws {
        subject.navigate(to: .dismiss(nil))

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .dismissedWithCompletionHandler)
    }

    /// `navigate(to:)` with `.loginRequest(_)` displays the login request view.
    @MainActor
    func test_navigate_loginRequest() throws {
        subject.navigate(to: .loginRequest(.fixture()))

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .replaced)
        XCTAssertTrue(action.view is LoginRequestView)
    }

    /// `start()` has no effect.
    @MainActor
    func test_start() {
        subject.start()
        XCTAssertTrue(stackNavigator.actions.isEmpty)
    }
}
