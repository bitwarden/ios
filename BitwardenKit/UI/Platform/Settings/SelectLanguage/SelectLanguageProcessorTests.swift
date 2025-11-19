import BitwardenKitMocks
import XCTest

@testable import BitwardenKit

// MARK: - SelectLanguageProcessorTests

class SelectLanguageProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var coordinator: MockCoordinator<SelectLanguageRoute, Void>!
    var delegate: MockSelectLanguageDelegate!
    var languageStateService: MockLanguageStateService!
    var subject: SelectLanguageProcessor!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        coordinator = MockCoordinator()
        delegate = MockSelectLanguageDelegate()
        languageStateService = MockLanguageStateService()
        let services = ServiceContainer.withMocks(
            languageStateService: languageStateService,
        )

        subject = SelectLanguageProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            delegate: delegate,
            services: services,
            state: SelectLanguageState(),
        )
    }

    override func tearDown() {
        super.tearDown()

        coordinator = nil
        delegate = nil
        languageStateService = nil
        subject = nil
    }

    // MARK: Tests

    /// `.receive(_:)` with `.dismiss` dismisses the view.
    @MainActor
    func test_receive_dismiss() {
        subject.receive(.dismiss)
        XCTAssertEqual(coordinator.routes.last, .dismiss)
    }

    /// `.receive(_:)` with `.languageTapped` with a new language saves the selection and shows
    /// the confirmation alert.
    @MainActor
    func test_receive_languageTapped() async throws {
        subject.receive(.languageTapped(.custom(languageCode: "th")))

        XCTAssertEqual(subject.state.currentLanguage, .custom(languageCode: "th"))
        XCTAssertEqual(languageStateService.appLanguage, .custom(languageCode: "th"))
        XCTAssertEqual(delegate.languageSelectedReceivedLanguageOption, .custom(languageCode: "th"))
        XCTAssertEqual(coordinator.alertShown.last, .languageChanged(to: LanguageOption("th").title) {})

        // Tapping the button on the alert should dismiss the view.
        let action = try XCTUnwrap(coordinator.alertShown.last?.alertActions.first)
        await action.handler?(action, [])

        XCTAssertEqual(coordinator.routes.last, .dismiss)
    }

    /// `.receive(_:)` with `.languageTapped` with the same language has no effect.
    @MainActor
    func test_receive_languageTapped_noChange() {
        subject.receive(.languageTapped(.default))
        XCTAssertTrue(coordinator.alertShown.isEmpty)
    }
}
