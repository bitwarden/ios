import XCTest

@testable import BitwardenShared

class AppearanceProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var coordinator: MockCoordinator<SettingsRoute>!
    var subject: AppearanceProcessor!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        coordinator = MockCoordinator()
        subject = AppearanceProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            state: AppearanceState()
        )
    }

    override func tearDown() {
        super.tearDown()

        coordinator = nil
        subject = nil
    }

    // MARK: Tests

    /// `receive(_:)` with `.toggleShowWebsiteIcons` updates the state's value.
    func test_toggleShowWebsiteIcons() {
        XCTAssertFalse(subject.state.isShowWebsiteIconsToggleOn)

        subject.receive(.toggleShowWebsiteIcons(true))

        XCTAssertTrue(subject.state.isShowWebsiteIconsToggleOn)
    }
}
