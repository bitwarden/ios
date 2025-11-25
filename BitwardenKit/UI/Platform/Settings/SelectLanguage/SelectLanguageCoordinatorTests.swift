import BitwardenKit
import BitwardenKitMocks
import XCTest

class SelectLanguageCoordinatorTests: BitwardenTestCase {
    // MARK: Properties

    var stackNavigator: MockStackNavigator!
    var subject: SelectLanguageCoordinator!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        stackNavigator = MockStackNavigator()

        subject = SelectLanguageCoordinator(
            services: ServiceContainer.withMocks(),
            stackNavigator: stackNavigator,
        )
    }

    override func tearDown() {
        super.tearDown()

        stackNavigator = nil
        subject = nil
    }

    // MARK: Tests

    /// `navigate(to:)` with `.dismiss` dismisses the top most view presented by the stack
    /// navigator.
    @MainActor
    func test_navigate_dismiss() throws {
        subject.navigate(to: .dismiss)

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .dismissed)
    }

    /// `navigate(to:)` with `.open(currentLanguage:)` presents the Select Language view.
    @MainActor
    func test_navigate_selectLanguage() throws {
        subject.navigate(to: .open(currentLanguage: LanguageOption("es")))

        let action = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(action.type, .presented)
        XCTAssertTrue(action.view is SelectLanguageView)
        XCTAssertEqual(action.embedInNavigationController, true)
    }

    /// `errorAlertServices` returns the services.
    @MainActor
    func test_errorAlertServices() {
        XCTAssertNotNil(subject.errorAlertServices)
    }
}
