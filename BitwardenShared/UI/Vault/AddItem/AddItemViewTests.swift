import SnapshotTesting
import SwiftUI
import ViewInspector
import XCTest

@testable import BitwardenShared

// MARK: - AddItemViewTests

class AddItemViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<AddItemState, AddItemAction, AddItemEffect>!
    var subject: AddItemView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        processor = MockProcessor(state: AddItemState())
        let store = Store(processor: processor)
        subject = AddItemView(store: store)
    }

    override func tearDown() {
        super.tearDown()
        processor = nil
        subject = nil
    }

    // MARK: Tests

    // MARK: Snapshots

    func test_snapshot_empty() {
        assertSnapshot(of: subject, as: .tallPortrait)
    }

    func test_snapshot_full_fieldsVisible() {
        processor.state.type = "Login"
        processor.state.name = "Name"
        processor.state.username = "username"
        processor.state.password = "password1!"
        processor.state.isFavoriteOn = true
        processor.state.isMasterPasswordRePromptOn = true
        processor.state.uri = URL.example.absoluteString
        processor.state.owner = "owner"
        processor.state.notes = "Notes"
        processor.state.folder = "Folder"

        processor.state.isPasswordVisible = true
        processor.state.isFolderVisible = true

        assertSnapshot(of: subject, as: .tallPortrait)
    }

    func test_snapshot_full_fieldsNotVisible() {
        processor.state.type = "Login"
        processor.state.name = "Name"
        processor.state.username = "username"
        processor.state.password = "password1!"
        processor.state.isFavoriteOn = true
        processor.state.isMasterPasswordRePromptOn = true
        processor.state.uri = URL.example.absoluteString
        processor.state.owner = "owner"
        processor.state.notes = "Notes"
        processor.state.folder = "Folder"

        assertSnapshot(of: subject, as: .tallPortrait)
    }
}
