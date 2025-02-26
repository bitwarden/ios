import BitwardenSdk
import XCTest

@testable import BitwardenShared

class AppExtensionProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var coordinator: MockCoordinator<SettingsRoute, SettingsEvent>!
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

    /// `didDismissExtensionSetup(enabled:)` sets the activated and enabled properties if it was enabled.
    @MainActor
    func test_didDismissExtensionSetup_enabled() {
        subject.didDismissExtensionSetup(enabled: true)

        XCTAssertTrue(subject.state.extensionActivated)
        XCTAssertTrue(subject.state.extensionEnabled)
    }

    /// `didDismissExtensionSetup(enabled:)` sets the activated property if it was activated, but not enabled.
    @MainActor
    func test_didDismissExtensionSetup_notEnabled() {
        subject.didDismissExtensionSetup(enabled: false)

        XCTAssertTrue(subject.state.extensionActivated)
        XCTAssertFalse(subject.state.extensionEnabled)
    }

    /// `didDismissExtensionSetup(enabled:)` doesn't toggle the enabled flag if the extension was reactivated.
    @MainActor
    func test_didDismissExtensionSetup_reenabled() {
        subject.didDismissExtensionSetup(enabled: true)
        subject.didDismissExtensionSetup(enabled: false)

        XCTAssertTrue(subject.state.extensionActivated)
        XCTAssertTrue(subject.state.extensionEnabled)
    }

    /// `receive(_:)` with `.activateButtonTapped` navigates to the extension setup flow.
    @MainActor
    func test_receive_activateButtonTapped() {
        subject.receive(.activateButtonTapped)

        XCTAssertEqual(coordinator.routes.last, .appExtensionSetup)
        XCTAssertIdentical(coordinator.contexts.last as? AppExtensionProcessor, subject)
    }
}
