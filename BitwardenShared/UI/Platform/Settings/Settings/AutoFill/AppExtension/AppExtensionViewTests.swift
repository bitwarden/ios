import BitwardenResources
import SnapshotTesting
import XCTest

@testable import BitwardenShared

class AppExtensionViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<AppExtensionState, AppExtensionAction, Void>!
    var subject: AppExtensionView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: AppExtensionState())
        let store = Store(processor: processor)

        subject = AppExtensionView(store: store)
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Tests

    /// Tapping the activate button dispatches the `.activateButtonTapped` action.
    @MainActor
    func test_activateButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.extensionEnable)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .activateButtonTapped)
    }

    // MARK: Snapshots

    /// The activate view renders correctly.
    @MainActor
    func test_snapshot_appExtension_activate() {
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5]
        )
    }

    /// The almost done view renders correctly.
    @MainActor
    func test_snapshot_appExtension_almostDone() {
        processor.state.extensionActivated = true
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5]
        )
    }

    /// The reactivate view renders correctly.
    @MainActor
    func test_snapshot_appExtension_reactivate() {
        processor.state.extensionActivated = true
        processor.state.extensionEnabled = true
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5]
        )
    }
}
