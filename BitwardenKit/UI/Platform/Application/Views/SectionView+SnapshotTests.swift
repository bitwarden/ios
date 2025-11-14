// swiftlint:disable:this file_name
import SnapshotTesting
import XCTest

@testable import BitwardenKit

class SectionViewTests: BitwardenTestCase {
    // MARK: Tests

    /// Test a snapshot of the sectionView.
    func disabletest_snapshot_sectionView() {
        for preview in SectionView_Previews._allPreviews {
            assertSnapshots(
                of: preview.content,
                as: [.defaultPortrait],
            )
        }
    }
}
