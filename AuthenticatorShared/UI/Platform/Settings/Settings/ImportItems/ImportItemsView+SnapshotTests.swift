// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import SnapshotTesting
import XCTest

@testable import AuthenticatorShared

class ImportItemsViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<ImportItemsState, ImportItemsAction, ImportItemsEffect>!
    var subject: ImportItemsView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: ImportItemsState())
        let store = Store(processor: processor)

        subject = ImportItemsView(store: store)
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Snapshots

    /// The empty view renders correctly.
    func disabletest_snapshot_empty() {
        assertSnapshots(of: subject, as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5])
    }
}
