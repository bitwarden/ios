import SnapshotTesting
import XCTest

@testable import BitwardenShared

class VaultSettingsViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<VaultSettingsState, VaultSettingsAction, Void>!
    var subject: VaultSettingsView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: VaultSettingsState())
        let store = Store(processor: processor)

        subject = VaultSettingsView(store: store)
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Tests

    /// Tapping the export vault button dispatches the `.exportVaultTapped` action.
    func test_exportVaultButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.exportVault)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .exportVaultTapped)
    }

    /// Tapping the folders button dispatches the `.foldersTapped` action.
    func test_foldersButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.folders)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .foldersTapped)
    }

    /// Tapping the version button dispatches the `.importItemsTapped` action.
    func test_importItemsButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.importItems)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .importItemsTapped)
    }

    // MARK: Snapshots

    /// The default view renders correctly.
    func test_snapshot_default() {
        assertSnapshots(of: subject, as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5])
    }
}
