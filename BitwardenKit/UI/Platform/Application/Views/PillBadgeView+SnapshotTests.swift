// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenResources
import SnapshotTesting
import SwiftUI
import XCTest

// MARK: - PillBadgeViewSnapshotTests

final class PillBadgeViewSnapshotTests: BitwardenTestCase {
    // MARK: Snapshots

    /// Check the snapshot for all pill badge styles.
    @MainActor
    func disabletest_snapshot_allStyles() {
        let stack = VStack(spacing: 16) {
            PillBadgeView(text: "Active", style: .success)
            PillBadgeView(text: "Canceled", style: .danger)
            PillBadgeView(text: "Past due", style: .warning)
        }
        .padding()

        assertSnapshots(of: stack, as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5])
    }
}
