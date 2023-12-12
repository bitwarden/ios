import SnapshotTesting
import XCTest

@testable import BitwardenShared

final class ToastViewTests: BitwardenTestCase {
    // MARK: Snapshots

    /// Tests all previews for the toast view.
    func test_snapshot_toastView_previews() {
        for preview in ToastView_Previews._allPreviews {
            assertSnapshots(
                matching: preview.content,
                as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5]
            )
        }
    }
}
