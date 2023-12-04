import SnapshotTesting
import XCTest

@testable import BitwardenShared

class SectionViewTests: BitwardenTestCase {
    // MARK: Tests

    /// Test a snapshot of the sectionView.
    func test_snapshot_sectionView() {
        for preview in SectionView_Previews._allPreviews {
            assertSnapshots(
                matching: preview.content,
                as: [.defaultPortrait]
            )
        }
    }
}
