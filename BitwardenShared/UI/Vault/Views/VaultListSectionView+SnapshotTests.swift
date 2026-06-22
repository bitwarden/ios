// swiftlint:disable:this file_name
import BitwardenResources
import SnapshotTesting
import SwiftUI
import XCTest

@testable import BitwardenShared
@testable import BitwardenSharedMocks

class VaultListSectionViewTests: BitwardenTestCase {
    // MARK: Properties

    let section = VaultListSection(
        id: "1",
        items: [VaultListItem.fixture()],
        name: "Name",
    )

    // MARK: Snapshots

    /// The expandable section renders correctly when expanded.
    @MainActor
    func disabletest_snapshot_expanded() {
        let subject = VaultListSectionView(section: section, isExpanded: .constant(true)) { item in
            Text(item.id)
        }
        assertSnapshots(
            of: subject,
            as: [.defaultPortrait, .defaultPortraitDark, .tallPortraitAX5(heightMultiple: 2)],
        )
    }

    /// The expandable section renders correctly when collapsed.
    @MainActor
    func disabletest_snapshot_collapsed() {
        let subject = VaultListSectionView(section: section, isExpanded: .constant(false)) { item in
            Text(item.id)
        }
        assertSnapshots(
            of: subject,
            as: [.defaultPortrait, .defaultPortraitDark, .tallPortraitAX5(heightMultiple: 2)],
        )
    }
}
