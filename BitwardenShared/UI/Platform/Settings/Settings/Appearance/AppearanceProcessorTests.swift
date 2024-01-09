import XCTest

@testable import BitwardenShared

class AppearanceProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var coordinator: MockCoordinator<SettingsRoute>!
    var stateService: MockStateService!
    var subject: AppearanceProcessor!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        coordinator = MockCoordinator()
        stateService = MockStateService()
        let services = ServiceContainer.withMocks(
            stateService: stateService
        )

        subject = AppearanceProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: services,
            state: AppearanceState()
        )
    }

    override func tearDown() {
        super.tearDown()

        coordinator = nil
        stateService = nil
        subject = nil
    }

    // MARK: Tests

    /// `perform(_:)` with `.loadData` sets the value in the state.
    func test_perform_loadData() async {
        XCTAssertEqual(subject.state.appTheme, .default)
        stateService.appTheme = .light
        stateService.showWebIcons = false

        await subject.perform(.loadData)

        XCTAssertEqual(subject.state.appTheme, .light)
        XCTAssertFalse(subject.state.isShowWebsiteIconsToggleOn)
    }

    /// `receive(_:)` with `.appThemeChanged` updates the theme.
    func test_receive_appThemeChanged() {
        subject.receive(.appThemeChanged(.dark))

        XCTAssertEqual(subject.state.appTheme, .dark)
        waitFor(stateService.appTheme == .dark)

        subject.receive(.appThemeChanged(.light))

        XCTAssertEqual(subject.state.appTheme, .light)
        waitFor(stateService.appTheme == .light)
    }

    /// `receive(_:)` with `.toggleShowWebsiteIcons` updates the value in the state and the cache.
    func test_receive_toggleShowWebsiteIcons() {
        XCTAssertFalse(subject.state.isShowWebsiteIconsToggleOn)

        subject.receive(.toggleShowWebsiteIcons(true))

        XCTAssertTrue(subject.state.isShowWebsiteIconsToggleOn)
        waitFor(stateService.showWebIcons == true)
    }
}
