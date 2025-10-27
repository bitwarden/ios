import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import BitwardenSdk
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

    // MARK: Tests

    /// Tests the add account visibility below the maximum account limit
    @MainActor
    func test_addAccountRow_subMaximumAccounts_showAdd() throws {
        processor.state = ProfileSwitcherState.subMaximumAccounts
        XCTAssertTrue(subject.store.state.showsAddAccount)
    }

    /// Tests the add account visibility below the maximum account limit
    @MainActor
    func test_addAccountRow_subMaximumAccounts_hideAdd() throws {
        let state = ProfileSwitcherState(
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
            shouldAlwaysHideAddAccount: true,
        )
        processor.state = state
        XCTAssertFalse(subject.store.state.showsAddAccount)
    }

    /// Tests the add account visibility at the maximum account limit
    @MainActor
    func test_addAccountRow_maximumAccounts() throws {
        processor.state = ProfileSwitcherState.maximumAccounts
        XCTAssertFalse(subject.store.state.showsAddAccount)
    }
}
