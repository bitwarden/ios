import SnapshotTesting
import XCTest

@testable import BitwardenShared

class AddLoginItemViewTests: BitwardenTestCase {
    // MARK: Tests

    /// Test a snapshot of the addLoginItemView.
    func test_snapshot_addLoginItemView() {
        for preview in AddLoginItemView_Previews._allPreviews {
            assertSnapshots(
                matching: preview.content,
                as: [.tallPortrait]
            )
        }
    }
}
