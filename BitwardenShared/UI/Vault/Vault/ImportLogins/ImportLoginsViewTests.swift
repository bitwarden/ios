import SnapshotTesting
import ViewInspector
import XCTest

@testable import BitwardenShared

class ImportLoginsViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<ImportLoginsState, ImportLoginsAction, ImportLoginsEffect>!
    var subject: ImportLoginsView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: ImportLoginsState())

        subject = ImportLoginsView(store: Store(processor: processor))
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Tests

    /// Tapping the dismiss button dispatches the `dismiss` action.
    @MainActor
    func test_dismiss_tap() throws {
        let button = try subject.inspect().find(button: Localizations.cancel)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .dismiss)
    }

    /// Tapping the get started button dispatches the `getStarted` action.
    @MainActor
    func test_getStarted_tap() throws {
        let button = try subject.inspect().find(button: Localizations.getStarted)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .getStarted)
    }

    /// Tapping the import logins later button performs the `importLoginsLater` effect.
    @MainActor
    func test_importLoginsLater_tap() async throws {
        let button = try subject.inspect().find(asyncButton: Localizations.importLoginsLater)
        try await button.tap()
        XCTAssertEqual(processor.effects.last, .importLoginsLater)
    }

    // MARK: Snapshots

    /// The import logins view renders correctly.
    @MainActor
    func test_snapshot_importLogins() {
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .tallPortraitAX5(heightMultiple: 2), .defaultLandscape]
        )
    }
}
