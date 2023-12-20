import SnapshotTesting
import XCTest

@testable import BitwardenShared

class AddEditCardItemViewTests: BitwardenTestCase {
    // MARK: Snapshots

    /// Test a snapshot of the addLoginItemView.
    func test_snapshot_addEditCardItemView() {
        for preview in AddEditCardItemView_Previews._allPreviews {
            assertSnapshots(
                matching: preview.content,
                as: [
                    .defaultPortrait,
                    .defaultPortraitDark,
                    .tallPortraitAX5(heightMultiple: 1.75),
                ]
            )
        }
    }
}
