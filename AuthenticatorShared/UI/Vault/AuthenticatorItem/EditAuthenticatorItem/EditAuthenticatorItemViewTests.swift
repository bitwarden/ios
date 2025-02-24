import SnapshotTesting
import SwiftUI
import ViewInspector
import XCTest

@testable import AuthenticatorShared

// MARK: - EditAuthenticatorItemViewTests

class EditAuthenticatorItemViewTests: AuthenticatorTestCase {
    // MARK: Properties

    var processor: MockProcessor<
        EditAuthenticatorItemState,
        EditAuthenticatorItemAction,
        EditAuthenticatorItemEffect
    >!
    var subject: EditAuthenticatorItemView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        let state = AuthenticatorItemState(
            existing: AuthenticatorItemView.fixture()
        )!

        processor = MockProcessor(state: state)
        subject = EditAuthenticatorItemView(
            store: Store(processor: processor)
        )
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Tests

    /// Test a snapshot of the ItemListView previews.
    func test_snapshot_EditAuthenticatorItemView_previews() {
        for preview in EditAuthenticatorItemView_Previews._allPreviews {
            assertSnapshots(
                of: preview.content,
                as: ["\(preview.displayName ?? "")": .portrait(heightMultiple: 1.25)]
            )
        }
    }
}
