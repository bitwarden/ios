import SnapshotTesting
import XCTest

@testable import AuthenticatorShared

class SectionViewTests: AuthenticatorTestCase {
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
