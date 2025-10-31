// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import BitwardenSdk
import SnapshotTesting
import SwiftUI
import XCTest

@testable import BitwardenShared

// MARK: - ProfileSwitcherViewTests

class ProfileSwitcherViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<ProfileSwitcherState, ProfileSwitcherAction, ProfileSwitcherEffect>!
    var subject: ProfileSwitcherView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        let account = ProfileSwitcherItem.anneAccount
        let state = ProfileSwitcherState(
            accounts: [account],
            activeAccountId: account.userId,
            allowLockAndLogout: true,
            isVisible: true,
        )
        processor = MockProcessor(state: state)
        subject = ProfileSwitcherView(store: Store(processor: processor))
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Snapshots

    func disabletest_snapshot_singleAccount() {
        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    @MainActor
    func disabletest_snapshot_multiAccount_unlocked_belowMaximum() {
        processor.state = ProfileSwitcherState(
            accounts: [
                ProfileSwitcherItem.anneAccount,
                ProfileSwitcherItem.fixture(
                    color: .yellow,
                    email: "bonus.bridge@bitwarden.com",
                    isUnlocked: true,
                    userInitials: "BB",
                ),
                ProfileSwitcherItem.fixture(
                    color: .teal,
                    email: "concurrent.claim@bitarden.com",
                    isUnlocked: true,
                    userInitials: "CC",
                ),
                ProfileSwitcherItem.fixture(
                    color: .indigo,
                    email: "double.dip@bitwarde.com",
                    isUnlocked: true,
                    userInitials: "DD",
                ),
            ],
            activeAccountId: ProfileSwitcherItem.anneAccount.userId,
            allowLockAndLogout: true,
            isVisible: true,
        )
        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    @MainActor
    func disabletest_snapshot_multiAccount_unlocked_atMaximum() {
        processor.state = ProfileSwitcherState.maximumAccounts
        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    @MainActor
    func disabletest_snapshot_multiAccount_unlocked_atMaximum_largeText() {
        processor.state = ProfileSwitcherState.maximumAccounts
        assertSnapshot(of: subject, as: .defaultPortraitAX5)
    }

    @MainActor
    func disabletest_snapshot_multiAccount_locked_belowMaximum() {
        processor.state = ProfileSwitcherState(
            accounts: [
                ProfileSwitcherItem.fixture(
                    color: .yellow,
                    email: "bonus.bridge@bitwarden.com",
                    isUnlocked: false,
                    userInitials: "BB",
                ),
                ProfileSwitcherItem.fixture(
                    color: .teal,
                    email: "concurrent.claim@bitarden.com",
                    isUnlocked: false,
                    userInitials: "CC",
                ),
                ProfileSwitcherItem.anneAccount,
                ProfileSwitcherItem.fixture(
                    color: .indigo,
                    email: "double.dip@bitwarde.com",
                    isUnlocked: false,
                    userInitials: "DD",
                ),
            ],
            activeAccountId: ProfileSwitcherItem.anneAccount.userId,
            allowLockAndLogout: true,
            isVisible: true,
        )
        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    @MainActor
    func disabletest_snapshot_multiAccount_locked_atMaximum() {
        processor.state = ProfileSwitcherState(
            accounts: [
                ProfileSwitcherItem.fixture(
                    color: .yellow,
                    email: "bonus.bridge@bitwarden.com",
                    isUnlocked: false,
                    userInitials: "BB",
                ),
                ProfileSwitcherItem.fixture(
                    color: .teal,
                    email: "concurrent.claim@bitarden.com",
                    isUnlocked: false,
                    userInitials: "CC",
                ),
                .anneAccount,
                ProfileSwitcherItem.fixture(
                    color: .indigo,
                    email: "double.dip@bitwarde.com",
                    isUnlocked: false,
                    userInitials: "DD",
                ),
                ProfileSwitcherItem.fixture(
                    color: .green,
                    email: "extra.edition@bitwarden.com",
                    isUnlocked: false,
                    userInitials: "EE",
                ),
            ],
            activeAccountId: ProfileSwitcherItem.anneAccount.userId,
            allowLockAndLogout: true,
            isVisible: true,
        )
        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    /// Test a snapshot of the ProfileSwitcherView previews.
    func disabletest_snapshot_profileSwitcherView_previews() {
        for preview in ProfileSwitcherView_Previews._allPreviews {
            assertSnapshots(
                of: preview.content,
                as: [.defaultPortrait],
            )
        }
    }
}
