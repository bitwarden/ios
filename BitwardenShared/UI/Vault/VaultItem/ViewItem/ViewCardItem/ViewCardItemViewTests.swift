import SnapshotTesting
import XCTest

@testable import BitwardenShared

class ViewCardItemViewTests: BitwardenTestCase {
    // MARK: Snapshots

    /// Test preview snapshots of the `ViewCardItemView`.
    ///
    func test_snapshot_viewCardItemView() {
        for preview in ViewCardItemView_Previews._allPreviews {
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
