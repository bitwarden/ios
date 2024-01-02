import SnapshotTesting
import XCTest

// MARK: - AppearanceViewTests

@testable import BitwardenShared

class AppearanceViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<AppearanceState, AppearanceAction, Void>!
    var subject: AppearanceView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: AppearanceState())
        let store = Store(processor: processor)

        subject = AppearanceView(store: store)
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Tests

    /// Tapping the language button dispatches the `.defaultDarkTheme` action.
    func test_defaultDarkThemeButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.defaultDarkTheme)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .defaultDarkThemeChanged)
    }

    /// Tapping the language button dispatches the `.defaultThemeChanged` action.
    func test_defaultThemeButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.theme)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .defaultThemeChanged)
    }

    /// Tapping the language button dispatches the `.languageTapped` action.
    func test_languageButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.language)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .languageTapped)
    }

    /// Tests the view renders correctly.
    func test_viewRender() {
        assertSnapshots(
            of: subject,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5]
        )
    }
}
