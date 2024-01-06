import BitwardenSdk
import XCTest

@testable import BitwardenShared

class AppExtensionProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var coordinator: MockCoordinator<SettingsRoute>!
    var subject: AppExtensionProcessor!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        coordinator = MockCoordinator()

        subject = AppExtensionProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            state: AppExtensionState()
        )
    }

    override func tearDown() {
        super.tearDown()

        coordinator = nil
        subject = nil
    }

    // MARK: Tests
}
