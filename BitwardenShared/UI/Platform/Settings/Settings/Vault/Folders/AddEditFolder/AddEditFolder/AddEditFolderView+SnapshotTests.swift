// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import SnapshotTesting
import XCTest

@testable import BitwardenShared

class AddEditFolderViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<AddEditFolderState, AddEditFolderAction, AddEditFolderEffect>!
    var subject: AddEditFolderView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: AddEditFolderState(mode: .add))
        let store = Store(processor: processor)

        subject = AddEditFolderView(store: store)
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Snapshots

    /// Tests the view renders correctly when the text field is empty.
    func disabletest_snapshot_add_empty() {
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5],
        )
    }

    /// Tests the view renders correctly when the text field is populated.
    @MainActor
    func disabletest_snapshot_add_populated() {
        processor.state.folderName = "Super cool folder name"
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5],
        )
    }

    /// Tests the view renders correctly when the text field is populated.
    @MainActor
    func disabletest_snapshot_edit_populated() {
        processor.state.mode = .edit(.fixture())
        processor.state.folderName = "Super cool folder name"
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5],
        )
    }
}
