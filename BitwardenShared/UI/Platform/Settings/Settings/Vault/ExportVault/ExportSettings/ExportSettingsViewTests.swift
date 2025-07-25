import BitwardenResources
import SnapshotTesting
import XCTest

@testable import BitwardenShared

class ExportSettingsViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<Void, ExportSettingsAction, Void>!
    var subject: ExportSettingsView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: ())
        let store = Store(processor: processor)

        subject = ExportSettingsView(store: store)
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Tests

    /// Tapping the export vault to file button dispatches the `.exportToFileTapped` action.
    @MainActor
    func test_exportVaultToFileButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.exportVaultToAFile)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .exportToFileTapped)
    }

    /// Tapping the export vault to another app button dispatches the `.exportToAppTapped` action.
    @MainActor
    func test_exportVaultToAnotherAppButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.exportVaultToAnotherApp)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .exportToAppTapped)
    }

    // MARK: Snapshots

    /// The default view renders correctly.
    @MainActor
    func test_snapshot_default() {
        assertSnapshots(of: subject, as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5])
    }
}
