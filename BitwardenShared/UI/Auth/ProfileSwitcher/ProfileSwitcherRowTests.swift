import SnapshotTesting
import SwiftUI
import ViewInspector
import XCTest

@testable import BitwardenShared

// MARK: - ProfileSwitcherRowTests

final class ProfileSwitcherRowTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<ProfileSwitcherRowState, ProfileSwitcherRowAction, ProfileSwitcherRowEffect>!
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
        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    /// Snapshot test for the active account row
    @MainActor
    func test_snapshot_active_divider() throws {
        processor.state = .init(
            shouldTakeAccessibilityFocus: false,
            showDivider: true,
            rowType: .active(.fixtureUnlocked)
        )
        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    /// Snapshot test for the active account row without a divider
    @MainActor
    func test_snapshot_active_noDivider() throws {
        processor.state = .init(
            shouldTakeAccessibilityFocus: false,
            showDivider: false,
            rowType: .active(.fixtureUnlocked)
        )
        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    /// Snapshot test for the alternate unlocked account row
    @MainActor
    func test_snapshot_alternate_unlocked() throws {
        processor.state = .init(
            shouldTakeAccessibilityFocus: false,
            rowType: .alternate(.fixtureUnlocked)
        )
        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    /// Snapshot test for the alternate locked account row
    @MainActor
    func test_snapshot_alternate_locked() throws {
        processor.state = .init(
            shouldTakeAccessibilityFocus: false,
            rowType: .alternate(.fixtureLocked)
        )
        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    /// Snapshot test for the alternate logged out row.
    @MainActor
    func test_snapshot_alternate_loggedOut() throws {
        processor.state = .init(
            shouldTakeAccessibilityFocus: false,
            rowType: .alternate(.fixtureLoggedOut)
        )
        assertSnapshot(of: subject, as: .defaultPortrait)
    }
}
