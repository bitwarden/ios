import BitwardenResources
import BitwardenSdk
import SnapshotTesting
import SwiftUI
import ViewInspector
import XCTest

@testable import BitwardenShared

// MARK: - ProfileSwitcherSheet Tests

class ProfileSwitcherSheetTests: BitwardenTestCase { // swiftlint:disable:this type_body_length

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
            isVisible: true
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

    /// Long pressing a profile row dispatches the `.accountLongPressed` action.
    @MainActor
    func test_accountRow_longPress_currentAccount() throws {
        let accountRow = try subject.inspect().find(button: "anne.account@bitwarden.com")
        try accountRow.labelView().callOnLongPressGesture()
        let currentAccount = processor.state.activeAccountProfile!
        waitFor(!processor.effects.isEmpty)

        XCTAssertEqual(processor.effects.last, .accountLongPressed(currentAccount))
    }

    /// Long pressing is disabled if lock and logout are not available.
    @MainActor
    func test_accountRow_longPress_currentAccount_noLockOrLogout() throws {
        processor.state.allowLockAndLogout = false
        processor.state.accounts[0].canBeLocked = false
        let accountRow = try subject.inspect().find(button: "anne.account@bitwarden.com")
        XCTAssertThrowsError(try accountRow.labelView().callOnLongPressGesture())
    }

    /// Tapping a profile row dispatches the `.accountPressed` action.
    @MainActor
    func test_accountRow_tap_currentAccount() throws {
        guard #unavailable(iOS 26) else {
            // TODO: PM-25516 Remove when ViewInspector updated
            throw XCTSkip("ViewInspector bug, waiting on new library version release. See #395")
        }

        let accountRow = try subject.inspect().find(button: "anne.account@bitwarden.com")
        try accountRow.labelView().callOnTapGesture()
        let currentAccount = processor.state.activeAccountProfile!
        waitFor(!processor.effects.isEmpty)

        XCTAssertEqual(processor.effects.last, .accountPressed(currentAccount))
    }

    /// Tapping a profile row dispatches the `.accountPressed` action.
    @MainActor
    func test_accountRow_tap_addAccount() throws {
        let addAccountRow = try subject.inspect().find(button: "Add account")
        try addAccountRow.tap()
        waitFor(!processor.effects.isEmpty)

        XCTAssertEqual(processor.effects.last, .addAccountPressed)
    }

    /// Long pressing an alternative profile row dispatches the `.accountLongPressed` action.
    @MainActor
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
            allowLockAndLogout: true,
            isVisible: true
        )
        let alternateRow = try subject.inspect().find(button: "alternate@bitwarden.com")
        try alternateRow.labelView().callOnLongPressGesture()
        waitFor(!processor.effects.isEmpty)

        XCTAssertEqual(processor.effects.last, .accountLongPressed(alternate))
    }

    /// Long pressing is disabled if lock and logout are not available.
    @MainActor
    func test_alternateAccountRow_longPress_currentAccount_noLockOrLogout() throws {
        let alternate = ProfileSwitcherItem.fixture(
            canBeLocked: false,
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
            allowLockAndLogout: false,
            isVisible: true
        )
        let alternateRow = try subject.inspect().find(button: "alternate@bitwarden.com")
        _ = try subject.inspect().find(button: "anne.account@bitwarden.com")
        XCTAssertThrowsError(try alternateRow.labelView().callOnLongPressGesture())
    }

    /// Tapping an alternative profile row dispatches the `.accountPressed` action.
    @MainActor
    func test_alternateAccountRow_tap_alternateAccount() throws {
        guard #unavailable(iOS 26) else {
            // TODO: PM-25516 Remove when ViewInspector updated
            throw XCTSkip("ViewInspector bug, waiting on new library version release. See #395")
        }

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
            allowLockAndLogout: true,
            isVisible: true
        )
        let alternateRow = try subject.inspect().find(button: "alternate@bitwarden.com")
        try alternateRow.labelView().callOnTapGesture()
        waitFor(!processor.effects.isEmpty)

        XCTAssertEqual(processor.effects.last, .accountPressed(alternate))
    }

    /// Tapping an alternative profile row dispatches the `.accountPressed` action.
    @MainActor
    func test_alternateAccountRows_tap_alternateEmptyAccount() throws {
        guard #unavailable(iOS 26) else {
            // TODO: PM-25516 Remove when ViewInspector updated
            throw XCTSkip("ViewInspector bug, waiting on new library version release. See #395")
        }

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
            allowLockAndLogout: true,
            isVisible: true
        )
        let secondAlternateRow = try subject.inspect().find(button: "")
        try secondAlternateRow.labelView().callOnTapGesture()
        waitFor(!processor.effects.isEmpty)

        XCTAssertEqual(processor.effects.last, .accountPressed(secondAlternate))
    }

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
            allowLockAndLogout: true,
            isVisible: true,
            shouldAlwaysHideAddAccount: true
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

    /// The close toolbar button closes the sheet.
    @MainActor
    func test_closeToolbarButton() throws {
        guard #unavailable(iOS 26) else {
            // TODO: PM-25516 Remove when ViewInspector updated
            throw XCTSkip("ViewInspector bug, waiting on new library version release. See #395")
        }

        let closeButton = try subject.inspect().find(button: Localizations.close)
        try closeButton.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .dismissTapped)
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
            allowLockAndLogout: true,
            isVisible: true
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
            allowLockAndLogout: true,
            isVisible: true
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
            allowLockAndLogout: true,
            isVisible: true
        )
        assertSnapshot(of: NavigationView { subject }, as: .defaultPortrait)
    }
}
