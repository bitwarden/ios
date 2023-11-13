import SnapshotTesting
import SwiftUI
import ViewInspector
import XCTest

@testable import BitwardenShared

// MARK: - ProfileSwitcherRowTests

final class ProfileSwitcherRowTests: BitwardenTestCase {
    let unlockedAccount = ProfileSwitcherItem(
        color: .purple,
        email: "anne.account@bitwarden.com",
        isUnlocked: true,
        userInitials: "AA"
    )

    let lockedAccount = ProfileSwitcherItem(
        color: .purple,
        email: "anne.account@bitwarden.com",
        isUnlocked: false,
        userInitials: "AA"
    )

    var processor: MockProcessor<ProfileSwitcherRowState, ProfileSwitcherRowAction, Void>!
    var subject: ProfileSwitcherRow!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        processor = MockProcessor(
            state: ProfileSwitcherRowState(
                shouldTakeAccessibilityFocus: false,
                showDivider: false,
                rowType: .addAccount
            )
        )
        let store = Store(processor: processor)
        subject = ProfileSwitcherRow(store: store)
    }

    override func tearDown() {
        super.tearDown()
        processor = nil
        subject = nil
    }

    /// Snapshot test for the add account row
    func test_snapshot_addAccount() throws {
        assertSnapshot(matching: subject, as: .defaultPortrait)
    }

    /// Snapshot test for the active account row
    func test_snapshot_active_divider() throws {
        processor.state = .init(
            shouldTakeAccessibilityFocus: false,
            showDivider: true,
            rowType: .active(unlockedAccount)
        )
        assertSnapshot(matching: subject, as: .defaultPortrait)
    }

    /// Snapshot test for the active account row without a divider
    func test_snapshot_active_noDivider() throws {
        processor.state = .init(
            shouldTakeAccessibilityFocus: false,
            showDivider: false,
            rowType: .active(unlockedAccount)
        )
        assertSnapshot(matching: subject, as: .defaultPortrait)
    }

    /// Snapshot test for the active account row
    func test_snapshot_alternate_unlocked() throws {
        processor.state = .init(
            shouldTakeAccessibilityFocus: false,
            rowType: .alternate(unlockedAccount)
        )
        assertSnapshot(matching: subject, as: .defaultPortrait)
    }

    /// Snapshot test for the active account row
    func test_snapshot_alternate_locked() throws {
        processor.state = .init(
            shouldTakeAccessibilityFocus: false,
            rowType: .alternate(lockedAccount)
        )
        assertSnapshot(matching: subject, as: .defaultPortrait)
    }
}
