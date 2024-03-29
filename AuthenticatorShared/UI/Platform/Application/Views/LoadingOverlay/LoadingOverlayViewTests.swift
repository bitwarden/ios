import SnapshotTesting
import XCTest

@testable import AuthenticatorShared

class LoadingOverlayViewTests: AuthenticatorTestCase {
    // MARK: Tests

    /// Test a snapshot of the loading overlay.
    func test_snapshot_loadingOverlay() {
        assertSnapshots(
            matching: LoadingOverlayView(state: .init(title: "Loading...")),
            as: [.defaultPortrait, .defaultPortraitDark]
        )
    }
}
