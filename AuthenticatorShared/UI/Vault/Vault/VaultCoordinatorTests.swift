import SwiftUI
import XCTest

@testable import AuthenticatorShared

// MARK: - VaultCoordinatorTests

class VaultCoordinatorTests: AuthenticatorTestCase {
    // MARK: Properties

    var delegate: MockVaultCoordinatorDelegate!
    var module: MockAppModule!
    var stackNavigator: MockStackNavigator!
    var subject: VaultCoordinator!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        delegate = MockVaultCoordinatorDelegate()
        module = MockAppModule()
        stackNavigator = MockStackNavigator()
        subject = VaultCoordinator(
            delegate: delegate,
            module: module,
            services: ServiceContainer.withMocks(),
            stackNavigator: stackNavigator
        )
    }

    override func tearDown() {
        super.tearDown()

        delegate = nil
        module = nil
        stackNavigator = nil
        subject = nil
    }

    // MARK: Tests

    /// `start()` has no effect.
    func test_start() {
        subject.start()

        XCTAssertTrue(stackNavigator.actions.isEmpty)
    }
}

class MockVaultCoordinatorDelegate: VaultCoordinatorDelegate {}
