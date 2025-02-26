import SnapshotTesting
import XCTest

@testable import BitwardenShared

class ViewCardItemViewTests: BitwardenTestCase {
    // MARK: Snapshots

    /// Test preview snapshots of the empty state `ViewCardItemView`.
    ///
    func test_snapshot_viewCardItemView_empty() {
        assertSnapshots(
            of: ViewCardItemView_Previews.emptyPreview,
            as: [
                .defaultPortrait,
            ]
        )
    }

    /// Test preview snapshots of the full visibility state `ViewCardItemView`.
    ///
    func test_snapshot_viewCardItemView_full() {
        assertSnapshots(
            of: ViewCardItemView_Previews.fullPreview,
            as: [
                .defaultPortrait,
            ]
        )
    }

    /// Test preview snapshots of the full visibility state `ViewCardItemView` in dark mode.
    ///
    func test_snapshot_viewCardItemView_full_dark() {
        assertSnapshots(
            of: ViewCardItemView_Previews.fullPreview,
            as: [
                .defaultPortraitDark,
            ]
        )
    }

    /// Test preview snapshots of the `ViewCardItemView` with a large font.
    ///
    func test_snapshot_viewCardItemView_full_largeFont() {
        assertSnapshots(
            of: ViewCardItemView_Previews.fullPreview,
            as: [
                .tallPortraitAX5(heightMultiple: 1.75),
            ]
        )
    }

    /// Test preview snapshots of the `ViewCardItemView` with a hidden number & code.
    ///
    func test_snapshot_viewCardItemView_hiddenCode() {
        assertSnapshots(
            of: ViewCardItemView_Previews.hiddenCodePreview,
            as: [
                .defaultPortrait,
            ]
        )
    }

    /// Test preview snapshots of the `ViewCardItemView` with no expiration data.
    ///
    func test_snapshot_viewCardItemView_noExpirationState() {
        assertSnapshots(
            of: ViewCardItemView_Previews.noExpiration,
            as: [
                .defaultPortrait,
            ]
        )
    }

    /// Test preview snapshots of the `ViewCardItemView` with partial expiration data.
    ///
    func test_snapshot_viewCardItemView_partialExpirationState() {
        assertSnapshots(
            of: ViewCardItemView_Previews.yearOnlyExpiration,
            as: [
                .defaultPortrait,
            ]
        )
    }
}
