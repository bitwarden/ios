import BitwardenKitMocks
import SwiftUI
import XCTest

@testable import BitwardenShared

class PasswordAutoFillCoordinatorTests: BitwardenTestCase {
    // MARK: Properties

    var delegate: MockPasswordAutoFillCoordinatorDelegate!
    var stackNavigator: MockStackNavigator!
    var subject: PasswordAutoFillCoordinator!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        delegate = MockPasswordAutoFillCoordinatorDelegate()
        stackNavigator = MockStackNavigator()

        subject = PasswordAutoFillCoordinator(
            delegate: delegate,
            services: ServiceContainer.withMocks(),
            stackNavigator: stackNavigator,
        )
    }

    override func tearDown() {
        super.tearDown()

        delegate = nil
        stackNavigator = nil
        subject = nil
    }

    // MARK: Tests

    /// `handleEvent(_:context:)` with `.didCompleteAuth` notifies the delegate that the user
    /// completed auth.
    @MainActor
    func test_handleEvent_didCompleteAuth() async {
        await subject.handleEvent(.didCompleteAuth)
        XCTAssertTrue(delegate.didCompleteAuthCalled)
    }

    /// `navigate(to:)` with `.dismiss` pops the most recently pushed view in the stack navigator.
    @MainActor
    func test_navigate_dismiss() throws {
        subject.navigate(to: .dismiss)
        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .popped)
    }

    /// `navigate(to:)` with `.passwordAutofill(mode:)` pushes the password autofill view onto the
    /// stack navigator.
    @MainActor
    func test_navigateTo_passwordAutofill() throws {
        subject.navigate(to: .passwordAutofill(mode: .onboarding))

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .pushed)
        XCTAssertTrue(action.view is PasswordAutoFillView)
    }

    /// `start()` has no effect.
    @MainActor
    func test_start() {
        subject.start()
        XCTAssertTrue(stackNavigator.actions.isEmpty)
    }
}

class MockPasswordAutoFillCoordinatorDelegate: PasswordAutoFillCoordinatorDelegate {
    var didCompleteAuthCalled = false

    func didCompleteAuth() {
        didCompleteAuthCalled = true
    }
}
