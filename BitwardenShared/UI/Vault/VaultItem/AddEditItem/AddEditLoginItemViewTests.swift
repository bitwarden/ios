import SnapshotTesting
import XCTest

@testable import BitwardenShared

class AddEditLoginItemViewTests: BitwardenTestCase {
    // MARK: Snapshots

    /// Test a snapshot of the addLoginItemView.
    func test_snapshot_addEditLoginItemView() {
        for preview in AddEditLoginItemView_Previews._allPreviews {
            assertSnapshots(
                matching: preview.content,
                as: [.tallPortrait]
            )
        }
    }
}
