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

    /// Tapping the back button for a step dispatches the `advancePreviousPage` action.
    @MainActor
    func test_step_back_tap() throws {
        processor.state.page = .step1
        let button = try subject.inspect().find(button: Localizations.back)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .advancePreviousPage)
    }

    /// Tapping the continue button for a step dispatches the `advanceNextPage` action.
    @MainActor
    func test_step_continue_tap() throws {
        processor.state.page = .step1
        let button = try subject.inspect().find(button: Localizations.continue)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .advanceNextPage)
    }

    // MARK: Snapshots

    /// The import logins intro page renders correctly.
    @MainActor
    func test_snapshot_importLoginsIntro() {
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .tallPortraitAX5(heightMultiple: 2), .defaultLandscape]
        )
    }

    /// The import logins step 1 page renders correctly.
    @MainActor
    func test_snapshot_importLoginsStep1() {
        processor.state.page = .step1
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .tallPortraitAX5(heightMultiple: 2.5), .defaultLandscape]
        )
    }
}
