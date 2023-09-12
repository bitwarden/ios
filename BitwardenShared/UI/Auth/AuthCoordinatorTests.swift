import SwiftUI
import XCTest

@testable import BitwardenShared

// MARK: - AuthCoordinatorTests

class AuthCoordinatorTests: BitwardenTestCase {
    // MARK: Properties

    var rootNavigator: MockRootNavigator!
    var stackNavigator: MockStackNavigator!
    var subject: AuthCoordinator!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        rootNavigator = MockRootNavigator()
        stackNavigator = MockStackNavigator()
        subject = AuthCoordinator(
            rootNavigator: rootNavigator,
            stackNavigator: stackNavigator
        )
    }

    override func tearDown() {
        super.tearDown()
        rootNavigator = nil
        stackNavigator = nil
        subject = nil
    }

    // MARK: Tests

    /// `navigate(to:)` with `.createAccount` pushes the create account view onto the stack navigator.
    func test_navigate_createAccount() {
        subject.navigate(to: .createAccount)

        // Placeholder assertion until the create account screen is added: BIT-157
        XCTAssertTrue(stackNavigator.actions.last?.view is CreateAccountView)
    }

    /// `navigate(to:)` with `.landing` pushes the landing view onto the stack navigator.
    func test_navigate_landing() {
        subject.navigate(to: .landing)
        XCTAssertTrue(stackNavigator.actions.last?.view is LandingView)
    }

    /// `navigate(to:)` with `.login` pushes the login view onto the stack navigator.
    func test_navigate_login() {
        subject.navigate(to: .login)

        // Placeholder assertion until the login screen is added: BIT-83
        XCTAssertTrue(stackNavigator.actions.last?.view is Text)
    }

    /// `navigate(to:)` with `.regionSelection` pushes the region selection view onto the stack navigator.
    func test_navigate_regionSelection() {
        subject.navigate(to: .regionSelection)

        // Placeholder assertion until the region selection screen is added: BIT-268
        XCTAssertTrue(stackNavigator.actions.last?.view is Text)
    }

    /// `rootNavigator` uses a weak reference and does not retain a value once the root navigator has been erased.
    func test_rootNavigator_resetWeakReference() {
        var rootNavigator: MockRootNavigator? = MockRootNavigator()
        subject = AuthCoordinator(
            rootNavigator: rootNavigator!,
            stackNavigator: stackNavigator
        )
        XCTAssertNotNil(subject.rootNavigator)

        rootNavigator = nil
        XCTAssertNil(subject.rootNavigator)
    }

    /// `start()` presents the stack navigator within the root navigator.
    func test_start() {
        subject.start()
        XCTAssertIdentical(rootNavigator.navigatorShown, stackNavigator)
    }
}
