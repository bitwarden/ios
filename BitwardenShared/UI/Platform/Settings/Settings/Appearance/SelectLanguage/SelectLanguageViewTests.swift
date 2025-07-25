import BitwardenResources
import SnapshotTesting
import XCTest

// MARK: - SelectLanguageViewTests

@testable import BitwardenShared

class SelectLanguageViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<SelectLanguageState, SelectLanguageAction, Void>!
    var subject: SelectLanguageView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: SelectLanguageState())
        let store = Store(processor: processor)

        subject = SelectLanguageView(store: store)
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Tests

    /// Tapping the cancel button dispatches the `.dismiss` action.
    @MainActor
    func test_cancelButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.cancel)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .dismiss)
    }

    /// Tapping a language button dispatches the `.languageTapped(_)` action.
    @MainActor
    func test_languageButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.defaultSystem)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .languageTapped(.default))
    }

    // MARK: Snapshots

    /// Test that the default view renders correctly.
    func test_snapshot_default() {
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [
                .defaultPortrait,
                .defaultPortraitDark,
                .tallPortraitAX5(),
            ]
        )
    }
}
