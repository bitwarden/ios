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

    /// The delegate method `languageSelected` should update the language.
    func test_languageSelected() {
        XCTAssertEqual(subject.state.currentLanguage, .default)

        subject.languageSelected(.custom(languageCode: "th"))

        XCTAssertEqual(subject.state.currentLanguage, .custom(languageCode: "th"))
    }

    /// `perform(_:)` with `.loadData` sets the value in the state.
    func test_perform_loadData() async {
        XCTAssertEqual(subject.state.appTheme, .default)
        stateService.appLanguage = .custom(languageCode: "de")
        stateService.appTheme = .light
        stateService.showWebIcons = false

        await subject.perform(.loadData)

        XCTAssertEqual(subject.state.currentLanguage, .custom(languageCode: "de"))
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

    /// `receive(_:)` with `.languageTapped` navigates to the select language view.
    func test_receive_languageTapped() async throws {
        subject.state.currentLanguage = .custom(languageCode: "th")

        subject.receive(.languageTapped)

        XCTAssertEqual(coordinator.routes.last, .selectLanguage(currentLanguage: LanguageOption("th")))
    }

    /// `receive(_:)` with `.toggleShowWebsiteIcons` updates the value in the state and the cache.
    func test_receive_toggleShowWebsiteIcons() {
        XCTAssertFalse(subject.state.isShowWebsiteIconsToggleOn)

        subject.receive(.toggleShowWebsiteIcons(true))

        XCTAssertTrue(subject.state.isShowWebsiteIconsToggleOn)
        waitFor(stateService.showWebIcons == true)
    }
}
