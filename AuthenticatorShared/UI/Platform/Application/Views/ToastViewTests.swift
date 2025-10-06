import SnapshotTesting
import XCTest

@testable import AuthenticatorShared

final class ToastViewTests: BitwardenTestCase {
    // MARK: Snapshots

    /// Tests all previews for the toast view.
    func disabletest_snapshot_toastView_previews() {
        for preview in ToastView_Previews._allPreviews {
            assertSnapshots(
                of: preview.content,
                as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5],
            )
        }
    }
}
