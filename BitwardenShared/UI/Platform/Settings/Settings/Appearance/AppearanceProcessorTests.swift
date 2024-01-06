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

    /// `receive(_:)` with `.themeButtonTapped` shows the alert and updates the theme.
    func test_receive_themeButtonTapped() async throws {
        subject.receive(.themeButtonTapped)

        XCTAssertEqual(coordinator.alertShown.last, .appThemeOptions { _ in })

        let alert = try XCTUnwrap(coordinator.alertShown.last)
        let darkButton = alert.alertActions[2]
        await darkButton.handler?(darkButton, [])

        XCTAssertEqual(stateService.appTheme, ThemeOption.dark.value)
        XCTAssertEqual(coordinator.routes.last, .updateTheme(theme: .dark))
        XCTAssertEqual(subject.state.appTheme, .dark)
    }

    /// `receive(_:)` with `.toggleShowWebsiteIcons` updates the state's value.
    func test_receive_toggleShowWebsiteIcons() {
        XCTAssertFalse(subject.state.isShowWebsiteIconsToggleOn)

        subject.receive(.toggleShowWebsiteIcons(true))

        XCTAssertTrue(subject.state.isShowWebsiteIconsToggleOn)
    }
}
