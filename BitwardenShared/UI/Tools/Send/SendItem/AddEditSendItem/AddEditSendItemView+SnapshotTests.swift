// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import SnapshotTesting
import SwiftUI
import XCTest

@testable import BitwardenShared

// MARK: - AddEditSendItemViewTests

class AddEditSendItemViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<AddEditSendItemState, AddEditSendItemAction, AddEditSendItemEffect>!
    var subject: AddEditSendItemView!

    /// A deletion date to use within the tests.
    let deletionDate = Date(year: 2023, month: 11, day: 5, hour: 9, minute: 41)

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        processor = MockProcessor(state: AddEditSendItemState())
        subject = AddEditSendItemView(store: Store(processor: processor))
    }

    // MARK: Snapshots

    @MainActor
    func disabletest_snapshot_file_empty() {
        processor.state.type = .file
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .tallPortraitAX5(heightMultiple: 1.1)],
        )
    }

    @MainActor
    func disabletest_snapshot_file_withValues() {
        processor.state.type = .file
        processor.state.name = "Name"
        processor.state.fileName = "example_file.txt"
        processor.state.fileData = Data("example".utf8)
        assertSnapshot(of: subject.navStackWrapped, as: .defaultPortrait)
    }

    @MainActor
    func disabletest_snapshot_file_withValues_prefilled() {
        processor.state.type = .file
        processor.state.name = "Name"
        processor.state.fileName = "example_file.txt"
        processor.state.fileData = Data("example".utf8)
        processor.state.mode = .shareExtension(.empty())
        assertSnapshot(of: subject.navStackWrapped, as: .defaultPortrait)
    }

    @MainActor
    func disabletest_snapshot_file_withOptions_empty() {
        processor.state.type = .file
        processor.state.isOptionsExpanded = true
        assertSnapshot(of: subject.navStackWrapped, as: .tallPortrait)
    }

    @MainActor
    func disabletest_snapshot_file_withOptions_withValues() {
        processor.state.type = .file
        processor.state.isOptionsExpanded = true
        processor.state.name = "Name"
        processor.state.fileName = "example_file.txt"
        processor.state.fileData = Data("example".utf8)
        processor.state.isHideTextByDefaultOn = true
        processor.state.deletionDate = .custom(deletionDate)
        processor.state.customDeletionDate = deletionDate
        processor.state.maximumAccessCount = 42
        processor.state.maximumAccessCountText = "42"
        processor.state.password = "pa$$w0rd"
        processor.state.notes = "Notes"
        processor.state.isHideMyEmailOn = true
        processor.state.isDeactivateThisSendOn = true
        assertSnapshot(of: subject.navStackWrapped, as: .tallPortrait)
    }

    @MainActor
    func disabletest_snapshot_file_edit_withOptions_withValues() {
        processor.state.mode = .edit
        processor.state.type = .file
        processor.state.isOptionsExpanded = true
        processor.state.name = "Name"
        processor.state.fileName = "example_file.txt"
        processor.state.fileSize = "420.42 KB"
        processor.state.deletionDate = .custom(deletionDate)
        processor.state.customDeletionDate = deletionDate
        processor.state.maximumAccessCount = 420
        processor.state.maximumAccessCountText = "420"
        processor.state.currentAccessCount = 42
        processor.state.password = "pa$$w0rd"
        processor.state.notes = "Notes"
        processor.state.isHideMyEmailOn = true
        processor.state.isDeactivateThisSendOn = true
        assertSnapshot(of: subject.navStackWrapped, as: .tallPortrait)
    }

    @MainActor
    func disabletest_snapshot_sendDisabled() {
        processor.state.isSendDisabled = true
        assertSnapshot(of: subject.navStackWrapped, as: .defaultPortrait)
    }

    @MainActor
    func disabletest_snapshot_sendHideEmailDisabled() {
        processor.state.isSendHideEmailDisabled = true
        assertSnapshot(of: subject.navStackWrapped, as: .defaultPortrait)
    }

    @MainActor
    func disabletest_snapshot_text_empty() {
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5],
        )
    }

    @MainActor
    func disabletest_snapshot_text_withValues() {
        processor.state.name = "Name"
        processor.state.text = "Text"
        processor.state.isHideTextByDefaultOn = true
        assertSnapshot(of: subject.navStackWrapped, as: .defaultPortrait)
    }

    @MainActor
    func disabletest_snapshot_text_withOptions_empty() {
        processor.state.isOptionsExpanded = true
        assertSnapshot(of: subject.navStackWrapped, as: .tallPortrait)
    }

    @MainActor
    func disabletest_snapshot_text_withOptions_withValues() {
        processor.state.isOptionsExpanded = true
        processor.state.name = "Name"
        processor.state.text = "Text."
        processor.state.isHideTextByDefaultOn = true
        processor.state.deletionDate = .custom(deletionDate)
        processor.state.customDeletionDate = deletionDate
        processor.state.maximumAccessCount = 42
        processor.state.maximumAccessCountText = "42"
        processor.state.password = "pa$$w0rd"
        processor.state.notes = "Notes."
        processor.state.isHideMyEmailOn = true
        processor.state.isDeactivateThisSendOn = true
        assertSnapshot(of: subject.navStackWrapped, as: .tallPortrait)
    }

    @MainActor
    func disabletest_snapshot_text_edit_withOptions_withValues() {
        processor.state.mode = .edit
        processor.state.type = .text
        processor.state.isOptionsExpanded = true
        processor.state.name = "Name"
        processor.state.text = "Text"
        processor.state.deletionDate = .custom(deletionDate)
        processor.state.customDeletionDate = deletionDate
        processor.state.maximumAccessCount = 420
        processor.state.maximumAccessCountText = "420"
        processor.state.currentAccessCount = 42
        processor.state.password = "pa$$w0rd"
        processor.state.notes = "Notes"
        processor.state.isHideMyEmailOn = true
        processor.state.isDeactivateThisSendOn = true
        assertSnapshot(of: subject.navStackWrapped, as: .tallPortrait)
    }

    @MainActor
    func disabletest_snapshot_text_extension_withValues() {
        processor.state.mode = .shareExtension(.singleAccount)
        processor.state.type = .text
        processor.state.name = "Name"
        processor.state.text = "Text"
        processor.state.isHideTextByDefaultOn = true
        assertSnapshot(of: subject.navStackWrapped, as: .defaultPortrait)
    }
}
