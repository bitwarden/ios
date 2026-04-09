// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import SnapshotTesting
import XCTest

@testable import AuthenticatorShared

class ExportItemsViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<ExportItemsState, ExportItemsAction, ExportItemsEffect>!
    var subject: ExportItemsView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: ExportItemsState())
        let store = Store(processor: processor)

        subject = ExportItemsView(store: store)
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
