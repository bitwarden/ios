// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import BitwardenSdk
import SwiftUI
import ViewInspector
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
            userInitials: "NA",
        )
        let current = processor.state.activeAccountProfile!
        processor.state = ProfileSwitcherState(
            accounts: [
                alternate,
                current,
            ],
            activeAccountId: current.userId,
            allowLockAndLogout: true,
            isVisible: true,
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
            userInitials: "NA",
        )
        let current = processor.state.activeAccountProfile!
        processor.state = ProfileSwitcherState(
            accounts: [
                alternate,
                current,
            ],
            activeAccountId: current.userId,
            allowLockAndLogout: false,
            isVisible: true,
        )
        let alternateRow = try subject.inspect().find(button: "alternate@bitwarden.com")
        _ = try subject.inspect().find(button: "anne.account@bitwarden.com")
        XCTAssertThrowsError(try alternateRow.labelView().callOnLongPressGesture())
    }

    /// Tapping an alternative profile row dispatches the `.accountPressed` action.
    @MainActor
    func test_alternateAccountRow_tap_alternateAccount() throws {
        let alternate = ProfileSwitcherItem.fixture(
            email: "alternate@bitwarden.com",
            userInitials: "NA",
        )
        let current = processor.state.activeAccountProfile!
        processor.state = ProfileSwitcherState(
            accounts: [
                alternate,
                current,
            ],
            activeAccountId: current.userId,
            allowLockAndLogout: true,
            isVisible: true,
        )
        let alternateRow = try subject.inspect().find(button: "alternate@bitwarden.com")
        try alternateRow.labelView().callOnTapGesture()
        waitFor(!processor.effects.isEmpty)

        XCTAssertEqual(processor.effects.last, .accountPressed(alternate))
    }

    /// Tapping an alternative profile row dispatches the `.accountPressed` action.
    @MainActor
    func test_alternateAccountRows_tap_alternateEmptyAccount() throws {
        let alternate = ProfileSwitcherItem.fixture(
            email: "locked@bitwarden.com",
            isUnlocked: false,
            userInitials: "LA",
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
            isVisible: true,
        )
        let secondAlternateRow = try subject.inspect().find(button: "")
        try secondAlternateRow.labelView().callOnTapGesture()
        waitFor(!processor.effects.isEmpty)

        XCTAssertEqual(processor.effects.last, .accountPressed(secondAlternate))
    }

    /// The close toolbar button closes the sheet.
    @MainActor
    func test_closeToolbarButton() throws {
        let closeButton = try subject.inspect().findCloseToolbarButton()
        try closeButton.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .dismissTapped)
    }

    // MARK: Snapshots

    // NB: There's not really a good way, it seems, to capture a view hierarchy when it's presenting a sheet.
    // cf. https://github.com/pointfreeco/swift-snapshot-testing/discussions/956
}
