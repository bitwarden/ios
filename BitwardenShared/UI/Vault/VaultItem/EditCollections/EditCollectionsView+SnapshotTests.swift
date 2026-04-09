// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import SnapshotTesting
import XCTest

@testable import BitwardenShared

class EditCollectionsViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<EditCollectionsState, EditCollectionsAction, EditCollectionsEffect>!
    var subject: EditCollectionsView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        processor = MockProcessor(state: EditCollectionsState(cipher: .fixture()))
        let store = Store(processor: processor)

        subject = EditCollectionsView(store: store)
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Previews

    /// The edit collections view renders correctly.
    @MainActor
    func disabletest_snapshot_editCollections() {
        processor.state.collections = [
            .fixture(id: "1", name: "Design", organizationId: "1"),
            .fixture(id: "2", name: "Engineering", organizationId: "1"),
        ]
        assertSnapshots(
            of: subject.navStackWrapped,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5],
        )
    }
}
