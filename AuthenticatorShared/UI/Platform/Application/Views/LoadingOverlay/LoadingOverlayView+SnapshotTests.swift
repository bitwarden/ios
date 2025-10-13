// swiftlint:disable:this file_name
import SnapshotTesting
import XCTest

@testable import AuthenticatorShared

class LoadingOverlayViewTests: BitwardenTestCase {
    // MARK: Tests

    /// Test a snapshot of the loading overlay.
    func disabletest_snapshot_loadingOverlay() {
        assertSnapshots(
            of: LoadingOverlayView(state: .init(title: "Loading...")),
            as: [.defaultPortrait, .defaultPortraitDark],
        )
    }
}
