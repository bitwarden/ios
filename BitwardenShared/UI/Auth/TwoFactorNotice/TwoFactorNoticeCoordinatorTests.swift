import SwiftUI
import TestHelpers
import XCTest

@testable import BitwardenShared

// MARK: - TwoFactorNoticeCoordinatorTests

class TwoFactorNoticeCoordinatorTests: BitwardenTestCase {
    // MARK: Properties

    // MARK: Properties

    var module: MockAppModule!
    var stackNavigator: MockStackNavigator!
    var subject: TwoFactorNoticeCoordinator!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        module = MockAppModule()
        stackNavigator = MockStackNavigator()

        let services = ServiceContainer.withMocks()

        subject = TwoFactorNoticeCoordinator(
            module: module,
            services: services,
            stackNavigator: stackNavigator
        )
    }

    override func tearDown() {
        super.tearDown()

        module = nil
        stackNavigator = nil
        subject = nil
    }

    // MARK: Tests

    /// `navigate(to:)` with `.dismiss` dismisses the screen in the stack navigator.
    @MainActor
    func test_navigate_dismiss() throws {
        subject.navigate(to: .dismiss)
        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .dismissed)
    }

    /// `navigate(to:)` with `.emailAccess` navigates to the email view.
    @MainActor
    func test_navigateTo_emailAccess() throws {
        subject.navigate(to: .emailAccess(allowDelay: true, emailAddress: "person@example.com"))

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .replaced)
        XCTAssertTrue(action.view is EmailAccessView)
    }

    /// `navigate(to:)` with `.setUpTwoFactor` navigates to the set up two factor view.
    @MainActor
    func test_navigateTo_setUpTwoFactor() throws {
        subject.navigate(to: .setUpTwoFactor(allowDelay: true, emailAddress: "person@example.com"))

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .pushed)
        XCTAssertTrue(action.view is SetUpTwoFactorView)
    }

    /// `start()` does nothing
    @MainActor
    func test_start() throws {
        subject.start()
        XCTAssertTrue(stackNavigator.actions.isEmpty)
    }
}
