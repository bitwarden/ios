// swiftlint:disable:this file_name
import BitwardenResources
import SnapshotTesting
import XCTest

@testable import AuthenticatorShared

// MARK: - ItemListCardViewTests

class ItemListCardViewTests: BitwardenTestCase {
    // MARK: Tests

    /// Test a snapshot of the ItemListView previews.
    func disabletest_snapshot_ItemListCardView_previews() {
        for preview in ItemListCardView_Previews._allPreviews {
            let name = preview.displayName ?? "Unknown"
            assertSnapshots(
                of: preview.content,
                as: [
                    "\(name)-portrait": .defaultPortrait,
                    "\(name)-portraitDark": .defaultPortraitDark,
                    "\(name)-portraitAX5": .tallPortraitAX5(heightMultiple: 3),
                ],
            )
        }
    }
}
