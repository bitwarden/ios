// swiftlint:disable:this file_name
import SnapshotTesting
import XCTest

@testable import BitwardenShared

class AddEditDriversLicenseItemViewTests: BitwardenTestCase {
    // MARK: Snapshots

    /// Test preview snapshots of the `AddEditDriversLicenseItemView`.
    ///
    func disabletest_snapshot_addEditDriversLicenseItemView() {
        for preview in AddEditDriversLicenseItemView_Previews._allPreviews {
            assertSnapshots(
                of: preview.content,
                as: [
                    .defaultPortrait,
                    .defaultPortraitDark,
                    .tallPortraitAX5(heightMultiple: 1.75),
                ],
            )
        }
    }
}
