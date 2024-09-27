import SwiftUI
import XCTest

@testable import BitwardenShared

// MARK: - ExtensionSetupCoordinatorTests

class ExtensionSetupCoordinatorTests: BitwardenTestCase {
    // MARK: Properties

    var configService: MockConfigService!
    var stackNavigator: MockStackNavigator!
    var subject: ExtensionSetupCoordinator!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        configService = MockConfigService()
        stackNavigator = MockStackNavigator()
        subject = ExtensionSetupCoordinator(
            appExtensionDelegate: MockAppExtensionDelegate(),
            services: ServiceContainer.withMocks(configService: configService),
            stackNavigator: stackNavigator
        )
    }

    override func tearDown() {
        super.tearDown()

        configService = nil
        stackNavigator = nil
        subject = nil
    }

    // MARK: Tests

    /// `navigate(to:)` with `.extensionActivation` replaces the stack navigator's stack with the
    /// extension activation view.
    @MainActor
    func test_navigateTo_extensionActivation() throws {
        subject.navigate(to: .extensionActivation(type: .autofillExtension))

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .replaced)
        XCTAssertTrue(action.view is ExtensionActivationView)
    }
}
