import SwiftUI
import XCTest

@testable import BitwardenShared

// MARK: - ExtensionSetupCoordinatorTests

class ExtensionSetupCoordinatorTests: BitwardenTestCase {
    // MARK: Properties

    var stackNavigator: MockStackNavigator!
    var subject: ExtensionSetupCoordinator!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        stackNavigator = MockStackNavigator()

        subject = ExtensionSetupCoordinator(
            appExtensionDelegate: MockAppExtensionDelegate(),
            stackNavigator: stackNavigator
        )
    }

    override func tearDown() {
        super.tearDown()

        stackNavigator = nil
        subject = nil
    }

    // MARK: Tests

    /// `navigate(to:)` with `.extensionActivation` replaces the stack navigator's stack with the
    /// extension activation view.
    func test_navigateTo_extensionActivation() throws {
        subject.navigate(to: .extensionActivation(type: .autofillExtension))

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .replaced)
        XCTAssertTrue(action.view is ExtensionActivationView)
    }
}
