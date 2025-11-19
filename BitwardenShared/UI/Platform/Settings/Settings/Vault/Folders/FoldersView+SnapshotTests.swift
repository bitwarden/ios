// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import SnapshotTesting
import XCTest

@testable import BitwardenShared

class FoldersViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<FoldersState, FoldersAction, FoldersEffect>!
    var subject: FoldersView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: FoldersState())
        let store = Store(processor: processor)

        subject = FoldersView(store: store)
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Snapshots

    /// The empty view renders correctly.
    @MainActor
    func disabletest_snapshot_empty() {
        processor.state.folders = []
        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    /// The folders view renders correctly.
    @MainActor
    func disabletest_snapshot_folders() {
        processor.state.folders = [
            .fixture(id: "test", name: "Secret Folder"),
            .fixture(id: "test2", name: "Double Secret Folder"),
        ]
        assertSnapshot(of: subject, as: .defaultPortrait)
    }
}
