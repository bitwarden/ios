import SnapshotTesting
import XCTest

@testable import BitwardenShared

class LoadingOverlayViewTests: BitwardenTestCase {
    // MARK: Tests

    /// Test a snapshot of the loading overlay.
    func test_snapshot_loadingOverlay() {
        assertSnapshots(
            of: LoadingOverlayView(state: .init(title: "Loading...")),
            as: [.defaultPortrait, .defaultPortraitDark]
        )
    }
}
