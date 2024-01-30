import XCTest

@testable import BitwardenShared

// MARK: - SelectLanguageProcessorTests

class SelectLanguageProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var coordinator: MockCoordinator<SettingsRoute, SettingsEvent>!
    var delegate: MockSelectLanguageDelegate!
    var stateService: MockStateService!
    var subject: SelectLanguageProcessor!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        coordinator = MockCoordinator()
        delegate = MockSelectLanguageDelegate()
        stateService = MockStateService()
        let services = ServiceContainer.withMocks(
            stateService: stateService
        )

        subject = SelectLanguageProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            delegate: delegate,
            services: services,
            state: SelectLanguageState()
        )
    }

    override func tearDown() {
        super.tearDown()

        coordinator = nil
        delegate = nil
        stateService = nil
        subject = nil
    }

    // MARK: Tests

    /// `.receive(_:)` with `.dismiss` dismisses the view.
    func test_receive_dismiss() {
        subject.receive(.dismiss)
        XCTAssertEqual(coordinator.routes.last, .dismiss)
    }

    /// `.receive(_:)` with `.languageTapped` with a new language saves the selection and shows
    /// the confirmation alert.
    func test_receive_languageTapped() async throws {
        subject.receive(.languageTapped(.custom(languageCode: "th")))

        XCTAssertEqual(subject.state.currentLanguage, .custom(languageCode: "th"))
        XCTAssertEqual(stateService.appLanguage, .custom(languageCode: "th"))
        XCTAssertEqual(delegate.selectedLanguage, .custom(languageCode: "th"))
        XCTAssertEqual(coordinator.alertShown.last, .languageChanged(to: LanguageOption("th").title) {})

        // Tapping the button on the alert should dismiss the view.
        let action = try XCTUnwrap(coordinator.alertShown.last?.alertActions.first)
        await action.handler?(action, [])

        XCTAssertEqual(coordinator.routes.last, .dismiss)
    }

    /// `.receive(_:)` with `.languageTapped` with the same language has no effect.
    func test_receive_languageTapped_noChange() {
        subject.receive(.languageTapped(.default))
        XCTAssertTrue(coordinator.alertShown.isEmpty)
    }
}

// MARK: - MockSelectLanguageDelegate

class MockSelectLanguageDelegate: SelectLanguageDelegate {
    var selectedLanguage: LanguageOption?

    func languageSelected(_ languageOption: LanguageOption) {
        selectedLanguage = languageOption
    }
}
