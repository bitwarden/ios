// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import BitwardenSdk
import SnapshotTesting
import SwiftUI
import XCTest

@testable import BitwardenShared

// MARK: - ProfileSwitcherSheet Tests

class ProfileSwitcherSheetTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<ProfileSwitcherState, ProfileSwitcherAction, ProfileSwitcherEffect>!
    var subject: ProfileSwitcherSheet!

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
        subject = ProfileSwitcherSheet(store: Store(processor: processor))
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Snapshots

    // NB: There's not really a good way, it seems, to capture a view hierarchy when it's presenting a sheet.
    // cf. https://github.com/pointfreeco/swift-snapshot-testing/discussions/956

    func disabletest_snapshot_singleAccount() {
        assertSnapshot(of: NavigationView { subject }, as: .defaultPortrait)
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
        assertSnapshot(of: NavigationView { subject }, as: .defaultPortrait)
    }

    @MainActor
    func disabletest_snapshot_multiAccount_unlocked_atMaximum() {
        processor.state = ProfileSwitcherState.maximumAccounts
        assertSnapshot(of: NavigationView { subject }, as: .defaultPortrait)
    }

    @MainActor
    func disabletest_snapshot_multiAccount_unlocked_atMaximum_largeText() {
        processor.state = ProfileSwitcherState.maximumAccounts
        assertSnapshot(of: NavigationView { subject }, as: .defaultPortraitAX5)
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
        assertSnapshot(of: NavigationView { subject }, as: .defaultPortrait)
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
        assertSnapshot(of: NavigationView { subject }, as: .defaultPortrait)
    }
}
