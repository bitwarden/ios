import SwiftUI
import XCTest

@testable import BitwardenShared

// MARK: - TwoFactorNoticeCoordinatorTests

class TwoFactorNoticeCoordinatorTests: BitwardenTestCase {
    // MARK: Properties

    // MARK: Properties

    var delegate: MockVaultCoordinatorDelegate!
    var errorReporter: MockErrorReporter!
    var module: MockAppModule!
    var stackNavigator: MockStackNavigator!
    var subject: TwoFactorNoticeCoordinator!
    var vaultRepository: MockVaultRepository!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        errorReporter = MockErrorReporter()
        delegate = MockVaultCoordinatorDelegate()
        module = MockAppModule()
        stackNavigator = MockStackNavigator()
        vaultRepository = MockVaultRepository()

        let services = ServiceContainer.withMocks(
            errorReporter: errorReporter,
            vaultRepository: vaultRepository
        )

        subject = TwoFactorNoticeCoordinator(
            module: module,
            services: services,
            stackNavigator: stackNavigator
        )
    }

    override func tearDown() {
        super.tearDown()

        delegate = nil
        errorReporter = nil
        module = nil
        stackNavigator = nil
        subject = nil
        vaultRepository = nil
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
        subject.navigate(to: .emailAccess(allowDelay: true))

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .replaced)
        XCTAssertTrue(action.view is EmailAccessView)
    }

    /// `navigate(to:)` with `.setUpTwoFactor` navigates to the set up two factor view.
    @MainActor
    func test_navigateTo_setUpTwoFactor() throws {
        subject.navigate(to: .setUpTwoFactor(allowDelay: true))

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .pushed)
        XCTAssertTrue(action.view is SetUpTwoFactorView)
    }

    /// `start()` does nothing
    @MainActor
    func test_start() throws {
        subject.start()
    }
}
