import BitwardenResources
import SnapshotTesting
import XCTest

// MARK: - AppearanceViewTests

@testable import BitwardenShared

class AppearanceViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<AppearanceState, AppearanceAction, AppearanceEffect>!
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

    /// Updating the value of the app theme sends the  `.appThemeChanged()` action.
    @MainActor
    func test_appThemeChanged_updateValue() throws {
        processor.state.appTheme = .light
        let menuField = try subject.inspect().find(bitwardenMenuField: Localizations.theme)
        try menuField.select(newValue: AppTheme.dark)
        XCTAssertEqual(processor.dispatchedActions.last, .appThemeChanged(.dark))
    }

    /// Tapping the language button dispatches the `.languageTapped` action.
    @MainActor
    func test_languageButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.language)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .languageTapped)
    }

    // MARK: Snapshots

    /// Tests the view renders correctly.
    func test_viewRender() {
        assertSnapshots(
            of: subject,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5]
        )
    }
}
