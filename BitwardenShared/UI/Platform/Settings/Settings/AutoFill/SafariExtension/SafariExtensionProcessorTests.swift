import BitwardenKitMocks
import BitwardenSdk
import XCTest

@testable import BitwardenShared

class SafariExtensionProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var coordinator: MockCoordinator<SettingsRoute, SettingsEvent>!
    var subject: SafariExtensionProcessor!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        coordinator = MockCoordinator()

        subject = SafariExtensionProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            state: SafariExtensionState(),
        )
    }

    override func tearDown() {
        super.tearDown()

        coordinator = nil
        subject = nil
    }

    // MARK: Tests

    @MainActor
    func test_didDismissSafariExtensionSetup_enabled() {
        subject.didDismissSafariExtensionSetup(enabled: true)

        XCTAssertTrue(subject.state.extensionActivated)
        XCTAssertTrue(subject.state.extensionEnabled)
    }

    @MainActor
    func test_didDismissSafariExtensionSetup_notEnabled() {
        subject.didDismissSafariExtensionSetup(enabled: false)

        XCTAssertTrue(subject.state.extensionActivated)
        XCTAssertFalse(subject.state.extensionEnabled)
    }

    @MainActor
    func test_receive_activateButtonTapped() {
        subject.receive(.activateButtonTapped)

        XCTAssertEqual(coordinator.routes.last, .safariExtensionSetup)
        XCTAssertIdentical(coordinator.contexts.last as? SafariExtensionProcessor, subject)
    }

    @MainActor
    func test_receive_activateButtonTapped_extensionActivated_continuesSafariSetupFlow() {
        subject.state.extensionActivated = true

        subject.receive(.activateButtonTapped)

        XCTAssertEqual(coordinator.routes.last, .safariExtensionSetup)
        XCTAssertIdentical(coordinator.contexts.last as? SafariExtensionProcessor, subject)
    }
}
