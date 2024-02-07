import BitwardenSdk
import SnapshotTesting
import SwiftUI
import ViewInspector
import XCTest

@testable import BitwardenShared

// MARK: - ProfileSwitcherViewTests

class ProfileSwitcherViewTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
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
            isVisible: true
        )
        processor = MockProcessor(state: state)
        subject = ProfileSwitcherView(store: Store(processor: processor))
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Tests

    /// Long pressing a profile row dispatches the `.accountLongPressed` action.
    func test_accountRow_longPress_currentAccount() throws {
        let accountRow = try subject.inspect().find(button: "anne.account@bitwarden.com")
        try accountRow.labelView().callOnLongPressGesture()
        let currentAccount = processor.state.activeAccountProfile!
        waitFor(!processor.effects.isEmpty)

        XCTAssertEqual(processor.effects.last, .accountLongPressed(currentAccount))
    }

    /// Tapping a profile row dispatches the `.accountPressed` action.
    func test_accountRow_tap_currentAccount() throws {
        let accountRow = try subject.inspect().find(button: "anne.account@bitwarden.com")
        try accountRow.labelView().callOnTapGesture()
        let currentAccount = processor.state.activeAccountProfile!
        waitFor(!processor.effects.isEmpty)

        XCTAssertEqual(processor.effects.last, .accountPressed(currentAccount))
    }

    /// Tapping a profile row dispatches the `.accountPressed` action.
    func test_accountRow_tap_addAccount() throws {
        let addAccountRow = try subject.inspect().find(button: "Add account")
        try addAccountRow.tap()
        waitFor(!processor.effects.isEmpty)

        XCTAssertEqual(processor.effects.last, .addAccountPressed)
    }

    /// Long pressing an alternative profile row dispatches the `.accountLongPressed` action.
    func test_alternateAccountRow_longPress_alternateAccount() throws {
        let alternate = ProfileSwitcherItem.fixture(
            email: "alternate@bitwarden.com",
            userInitials: "NA"
        )
        let current = processor.state.activeAccountProfile!
        processor.state = ProfileSwitcherState(
            accounts: [
                alternate,
                current,
            ],
            activeAccountId: current.userId,
            isVisible: true
        )
        let addAccountRow = try subject.inspect().find(button: "alternate@bitwarden.com")
        try addAccountRow.labelView().callOnLongPressGesture()
        waitFor(!processor.effects.isEmpty)

        XCTAssertEqual(processor.effects.last, .accountLongPressed(alternate))
    }

    /// Tapping an alternative profile row dispatches the `.accountPressed` action.
    func test_alternateAccountRow_tap_alternateAccount() throws {
        let alternate = ProfileSwitcherItem.fixture(
            email: "alternate@bitwarden.com",
            userInitials: "NA"
        )
        let current = processor.state.activeAccountProfile!
        processor.state = ProfileSwitcherState(
            accounts: [
                alternate,
                current,
            ],
            activeAccountId: current.userId,
            isVisible: true
        )
        let addAccountRow = try subject.inspect().find(button: "alternate@bitwarden.com")
        try addAccountRow.labelView().callOnTapGesture()
        waitFor(!processor.effects.isEmpty)

        XCTAssertEqual(processor.effects.last, .accountPressed(alternate))
    }

    /// Tapping an alternative profile row dispatches the `.accountPressed` action.
    func test_alternateAccountRows_tap_alternateEmptyAccount() throws {
        let alternate = ProfileSwitcherItem.fixture(
            email: "locked@bitwarden.com",
            isUnlocked: false,
            userInitials: "LA"
        )
        let secondAlternate = ProfileSwitcherItem.fixture()
        let alternateAccounts = [
            alternate,
            secondAlternate,
        ]
        let current = processor.state.activeAccountProfile!
        processor.state = ProfileSwitcherState(
            accounts: alternateAccounts + [current],
            activeAccountId: current.userId,
            isVisible: true
        )
        let addAccountRow = try subject.inspect().find(button: "")
        try addAccountRow.labelView().callOnTapGesture()
        waitFor(!processor.effects.isEmpty)

        XCTAssertEqual(processor.effects.last, .accountPressed(secondAlternate))
    }

    /// Tapping the background triggers a `.backgroundPressed` action.
    func test_background_tap() throws {
        let view = try subject.inspect().view(ProfileSwitcherView.self)
        let background = view.first
        try background?.callOnTapGesture()

        XCTAssertEqual(processor.dispatchedActions.last, .backgroundPressed)
    }

    /// Tests the add account visibility below the maximum account limit
    func test_addAccountRow_subMaximumAccounts_showAdd() throws {
        processor.state = ProfileSwitcherState.subMaximumAccounts
        XCTAssertTrue(subject.store.state.showsAddAccount)
    }

    /// Tests the add account visibility below the maximum account limit
    func test_addAccountRow_subMaximumAccounts_hideAdd() throws {
        let state = ProfileSwitcherState(
            accounts: [
                ProfileSwitcherItem.anneAccount,
                ProfileSwitcherItem.fixture(
                    color: .yellow,
                    email: "bonus.bridge@bitwarden.com",
                    isUnlocked: true,
                    userInitials: "BB"
                ),
                ProfileSwitcherItem.fixture(
                    color: .teal,
                    email: "concurrent.claim@bitarden.com",
                    isUnlocked: true,
                    userInitials: "CC"
                ),
                ProfileSwitcherItem.fixture(
                    color: .indigo,
                    email: "double.dip@bitwarde.com",
                    isUnlocked: true,
                    userInitials: "DD"
                ),
            ],
            activeAccountId: ProfileSwitcherItem.anneAccount.userId,
            isVisible: true,
            shouldAlwaysHideAddAccount: true
        )
        processor.state = state
        XCTAssertFalse(subject.store.state.showsAddAccount)
    }

    /// Tests the add account visibility at the maximum account limit
    func test_addAccountRow_maximumAccounts() throws {
        processor.state = ProfileSwitcherState.maximumAccounts
        XCTAssertFalse(subject.store.state.showsAddAccount)
    }

    // MARK: Snapshots

    func test_snapshot_singleAccount() {
        assertSnapshot(matching: subject, as: .defaultPortrait)
    }

    func test_snapshot_multiAccount_unlocked_belowMaximum() {
        processor.state = ProfileSwitcherState(
            accounts: [
                ProfileSwitcherItem.anneAccount,
                ProfileSwitcherItem.fixture(
                    color: .yellow,
                    email: "bonus.bridge@bitwarden.com",
                    isUnlocked: true,
                    userInitials: "BB"
                ),
                ProfileSwitcherItem.fixture(
                    color: .teal,
                    email: "concurrent.claim@bitarden.com",
                    isUnlocked: true,
                    userInitials: "CC"
                ),
                ProfileSwitcherItem.fixture(
                    color: .indigo,
                    email: "double.dip@bitwarde.com",
                    isUnlocked: true,
                    userInitials: "DD"
                ),
            ],
            activeAccountId: ProfileSwitcherItem.anneAccount.userId,
            isVisible: true
        )
        assertSnapshot(matching: subject, as: .defaultPortrait)
    }

    func test_snapshot_multiAccount_unlocked_atMaximum() {
        processor.state = ProfileSwitcherState.maximumAccounts
        assertSnapshot(matching: subject, as: .defaultPortrait)
    }

    func test_snapshot_multiAccount_unlocked_atMaximum_largeText() {
        processor.state = ProfileSwitcherState.maximumAccounts
        assertSnapshot(matching: subject, as: .defaultPortraitAX5)
    }

    func test_snapshot_multiAccount_locked_belowMaximum() {
        processor.state = ProfileSwitcherState(
            accounts: [
                ProfileSwitcherItem.fixture(
                    color: .yellow,
                    email: "bonus.bridge@bitwarden.com",
                    isUnlocked: false,
                    userInitials: "BB"
                ),
                ProfileSwitcherItem.fixture(
                    color: .teal,
                    email: "concurrent.claim@bitarden.com",
                    isUnlocked: false,
                    userInitials: "CC"
                ),
                ProfileSwitcherItem.anneAccount,
                ProfileSwitcherItem.fixture(
                    color: .indigo,
                    email: "double.dip@bitwarde.com",
                    isUnlocked: false,
                    userInitials: "DD"
                ),
            ],
            activeAccountId: ProfileSwitcherItem.anneAccount.userId,
            isVisible: true
        )
        assertSnapshot(matching: subject, as: .defaultPortrait)
    }

    func test_snapshot_multiAccount_locked_atMaximum() {
        processor.state = ProfileSwitcherState(
            accounts: [
                ProfileSwitcherItem.fixture(
                    color: .yellow,
                    email: "bonus.bridge@bitwarden.com",
                    isUnlocked: false,
                    userInitials: "BB"
                ),
                ProfileSwitcherItem.fixture(
                    color: .teal,
                    email: "concurrent.claim@bitarden.com",
                    isUnlocked: false,
                    userInitials: "CC"
                ),
                .anneAccount,
                ProfileSwitcherItem.fixture(
                    color: .indigo,
                    email: "double.dip@bitwarde.com",
                    isUnlocked: false,
                    userInitials: "DD"
                ),
                ProfileSwitcherItem.fixture(
                    color: .green,
                    email: "extra.edition@bitwarden.com",
                    isUnlocked: false,
                    userInitials: "EE"
                ),
            ],
            activeAccountId: ProfileSwitcherItem.anneAccount.userId,
            isVisible: true
        )
        assertSnapshot(matching: subject, as: .defaultPortrait)
    }

    /// Test a snapshot of the ProfileSwitcherView previews.
    func test_snapshot_profileSwitcherView_previews() {
        for preview in ProfileSwitcherView_Previews._allPreviews {
            assertSnapshots(
                matching: preview.content,
                as: [.defaultPortrait]
            )
        }
    }
}
