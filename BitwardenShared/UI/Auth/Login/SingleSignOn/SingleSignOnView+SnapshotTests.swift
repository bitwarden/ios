// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import SnapshotTesting
import XCTest

@testable import BitwardenShared

class SingleSignOnViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<SingleSignOnState, SingleSignOnAction, SingleSignOnEffect>!
    var subject: SingleSignOnView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: SingleSignOnState())
        let store = Store(processor: processor)

        subject = SingleSignOnView(store: store)
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Snapshots

    /// Tests the view renders correctly when the text field is empty.
    func disabletest_snapshot_empty() {
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5],
        )
    }

    /// Tests the view renders correctly when the text field is populated.
    @MainActor
    func disabletest_snapshot_populated() {
        processor.state.identifierText = "Insert cool identifier here"
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5],
        )
    }
}
