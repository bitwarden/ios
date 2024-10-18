import SnapshotTesting
import ViewInspector
import XCTest

@testable import BitwardenShared

class ImportLoginsSuccessViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<Void, ImportLoginsSuccessAction, Void>!
    var subject: ImportLoginsSuccessView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: ())

        subject = ImportLoginsSuccessView(store: Store(processor: processor))
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Tests

    /// Tapping the close button dispatches the `dismiss` action.
    @MainActor
    func test_close_tap() throws {
        let button = try subject.inspect().find(button: Localizations.close)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .dismiss)
    }

    /// Tapping the got it button dispatches the `dismiss` action.
    @MainActor
    func test_gotIt_tap() throws {
        let button = try subject.inspect().find(button: Localizations.gotIt)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .dismiss)
    }

    // MARK: Snapshots

    /// The import logins success page renders correctly.
    @MainActor
    func test_snapshot_importLoginsSuccess() {
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .tallPortraitAX5(heightMultiple: 3), .defaultLandscape]
        )
    }
}
