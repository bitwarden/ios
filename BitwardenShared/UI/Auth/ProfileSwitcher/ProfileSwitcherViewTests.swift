import BitwardenSdk
import SnapshotTesting
import SwiftUI
import ViewInspector
import XCTest

@testable import BitwardenShared

// MARK: - ProfileSwitcherViewTests

class ProfileSwitcherViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<ProfileSwitcherState, ProfileSwitcherAction, Void>!
    var subject: ProfileSwitcherView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        let state = ProfileSwitcherState(
            currentAccountProfile: ProfileSwitcherItem(
                color: .purple,
                email: "anne.account@bitwarden.com",
                userInitials: "AA"
            ),
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

    /// Tapping a profile row dispatches the `.accountPressed` action.
    func test_accountRow_tap_currentAccount() throws {
        let accountRow = try subject.inspect().find(button: "anne.account@bitwarden.com")
        try accountRow.tap()
        let currentAccount = processor.state.currentAccountProfile

        XCTAssertEqual(processor.dispatchedActions.last, .accountPressed(currentAccount))
    }

    /// Tapping a profile row dispatches the `.accountPressed` action.
    func test_accountRow_tap_addAccount() throws {
        let addAccountRow = try subject.inspect().find(button: "Add account")
        try addAccountRow.tap()

        XCTAssertEqual(processor.dispatchedActions.last, .addAccountPressed)
    }

    /// Tapping an alternative profile row dispatches the `.accountPressed` action.
    func test_alternateAccountRow_tap_alternateAccount() throws {
        let alternate = ProfileSwitcherItem(
            email: "alternate@bitwarden.com",
            userInitials: "NA"
        )
        processor.state = ProfileSwitcherState(
            alternateAccounts: [alternate],
            currentAccountProfile: processor.state.currentAccountProfile,
            isVisible: true
        )
        let addAccountRow = try subject.inspect().find(button: "alternate@bitwarden.com")
        try addAccountRow.tap()

        XCTAssertEqual(processor.dispatchedActions.last, .accountPressed(alternate))
    }

    /// Tapping an alternative profile row dispatches the `.accountPressed` action.
    func test_alternateAccountRows_tap_alternateEmptyAccount() throws {
        let alternate = ProfileSwitcherItem(
            email: "locked@bitwarden.com",
            isUnlocked: false,
            userInitials: "LA"
        )
        let secondAlternate = ProfileSwitcherItem()
        let alternateAccounts = [
            alternate,
            secondAlternate,
        ]
        processor.state = ProfileSwitcherState(
            alternateAccounts: alternateAccounts,
            currentAccountProfile: processor.state.currentAccountProfile,
            isVisible: true
        )
        let addAccountRow = try subject.inspect().find(button: "")
        try addAccountRow.tap()

        XCTAssertEqual(processor.dispatchedActions.last, .accountPressed(secondAlternate))
    }

    /// Tapping the background triggers a `.backgroundPressed` action.
    func test_background_tap() throws {
        let background = try subject.inspect().zStack().color(0)
        try background.callOnTapGesture()

        XCTAssertEqual(processor.dispatchedActions.last, .backgroundPressed)
    }

    // MARK: Snapshots

    func test_snapshot_singleAccount() {
        assertSnapshot(matching: subject, as: .defaultPortrait)
    }

    func test_snapshot_multiAccount_unlocked() {
        processor.state = ProfileSwitcherState(
            alternateAccounts: [
                ProfileSwitcherItem(
                    color: .yellow,
                    email: "bonus.bridge@bitwarden.com",
                    isUnlocked: true,
                    userInitials: "BB"
                ),
                ProfileSwitcherItem(
                    color: .teal,
                    email: "concurrent.claim@bitarden.com",
                    isUnlocked: true,
                    userInitials: "CC"
                ),
                ProfileSwitcherItem(
                    color: .indigo,
                    email: "double.dip@bitwarde.com",
                    isUnlocked: true,
                    userInitials: "DD"
                ),
                ProfileSwitcherItem(
                    color: .green,
                    email: "extra.edition@bitwarden.com",
                    isUnlocked: true,
                    userInitials: "EE"
                ),
            ],
            currentAccountProfile: ProfileSwitcherItem(
                color: .purple,
                email: "anne.account@bitwarden.com",
                userInitials: "AA"
            ),
            isVisible: true
        )
        assertSnapshot(matching: subject, as: .defaultPortrait)
    }

    func test_snapshot_multiAccount_locked() {
        processor.state = ProfileSwitcherState(
            alternateAccounts: [
                ProfileSwitcherItem(
                    color: .yellow,
                    email: "bonus.bridge@bitwarden.com",
                    isUnlocked: false,
                    userInitials: "BB"
                ),
                ProfileSwitcherItem(
                    color: .teal,
                    email: "concurrent.claim@bitarden.com",
                    isUnlocked: false,
                    userInitials: "CC"
                ),
                ProfileSwitcherItem(
                    color: .indigo,
                    email: "double.dip@bitwarde.com",
                    isUnlocked: false,
                    userInitials: "DD"
                ),
                ProfileSwitcherItem(
                    color: .green,
                    email: "extra.edition@bitwarden.com",
                    isUnlocked: false,
                    userInitials: "EE"
                ),
            ],
            currentAccountProfile: ProfileSwitcherItem(
                color: .purple,
                email: "anne.account@bitwarden.com",
                userInitials: "AA"
            ),
            isVisible: true
        )
        assertSnapshot(matching: subject, as: .defaultPortrait)
    }
}
