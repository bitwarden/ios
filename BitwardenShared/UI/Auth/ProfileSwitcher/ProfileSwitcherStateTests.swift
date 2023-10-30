import XCTest

@testable import BitwardenShared

// MARK: - ProfileSwitcherStateTests

final class ProfileSwitcherStateTests: BitwardenTestCase {
    // MARK: Properties

    var subject: ProfileSwitcherState?

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        subject = .empty
    }

    override func tearDown() {
        super.tearDown()

        subject = nil
    }

    /// Tests the static empty var accounts
    func test_empty_accounts() {
        XCTAssertEqual(subject?.accounts.count, 1)
    }

    /// Tests the static empty var alternateAccounts
    func test_empty_alternateAccounts() {
        XCTAssertEqual(subject?.alternateAccounts, [])
    }

    /// Tests the static empty var current account color
    func test_empty_currentAccount_color() {
        XCTAssertEqual(subject?.currentAccountProfile.color, .purple)
    }

    /// Tests the static empty var current account email
    func test_empty_currentAccount_email() {
        XCTAssertEqual(subject?.currentAccountProfile.email, "")
    }

    /// Tests the static empty var current account isUnlocked
    func test_empty_currentAccount_isUnlocked() {
        let isUnlocked = subject?.currentAccountProfile.isUnlocked

        XCTAssertTrue(isUnlocked!)
    }

    /// Setting the alternate accounts should succeed
    func test_empty_setAlternates_alternatesMatch() {
        let newAlternates = [
            ProfileSwitcherItem(),
        ]
        subject?.alternateAccounts = newAlternates

        XCTAssertEqual(newAlternates, subject?.alternateAccounts)
    }

    /// Setting the alternate accounts should succeed
    func test_empty_setAlternates_accountsMatch() {
        let alternate = ProfileSwitcherItem()
        let newAlternates = [
            alternate,
        ]
        let current = subject!.currentAccountProfile
        subject?.alternateAccounts = newAlternates
        let expectedAccounts = [
            alternate,
            current,
        ]

        XCTAssertEqual(subject?.accounts, expectedAccounts)
    }

    /// Tests the static empty var current account initials
    func test_empty_currentAccount_userInitials() {
        XCTAssertEqual(subject?.currentAccountProfile.userInitials, "")
    }

    /// Tests the init succeeds with accounts matching
    func test_init_accountsWithCurrent_accountsMatch() {
        let account = ProfileSwitcherItem()
        let accounts = [
            account,
            ProfileSwitcherItem(isUnlocked: true),
        ]
        subject = ProfileSwitcherState(
            alternateAccounts: accounts,
            currentAccountProfile: account,
            isVisible: false
        )

        XCTAssertEqual(accounts, subject?.alternateAccounts)
    }

    /// Tests the init succeeds with current account matching
    func test_init_accountsWithCurrent_currentProfilesMatch() {
        let account = ProfileSwitcherItem()
        let accounts = [
            account,
            ProfileSwitcherItem(isUnlocked: true),
        ]
        subject = ProfileSwitcherState(
            alternateAccounts: accounts,
            currentAccountProfile: account,
            isVisible: true
        )

        XCTAssertEqual(account, subject?.currentAccountProfile)
    }

    /// Tests the init succeeds with accounts matching
    func test_init_currentAccount_accountsMatch() {
        let account = ProfileSwitcherItem()
        subject = ProfileSwitcherState(
            currentAccountProfile: account,
            isVisible: true
        )

        XCTAssertEqual([account], subject?.accounts)
    }

    /// Tests the init succeeds with accounts matching
    func test_init_currentAccount_alternateAccountsMatch() {
        let account = ProfileSwitcherItem()
        subject = ProfileSwitcherState(
            currentAccountProfile: account,
            isVisible: true
        )

        XCTAssertEqual([], subject?.alternateAccounts)
    }

    /// Tests the init succeeds with current account matching
    func test_init_currentAccount_currentProfilesMatch() {
        let account = ProfileSwitcherItem()
        subject = ProfileSwitcherState(
            currentAccountProfile: account,
            isVisible: true
        )

        XCTAssertEqual(account, subject?.currentAccountProfile)
    }

    /// Tests the init succeeds with accounts matching
    func test_init_currentAndAlternateAccounts_accountsMatch() {
        let account1 = ProfileSwitcherItem()
        let alternates = [
            ProfileSwitcherItem(isUnlocked: false),
            ProfileSwitcherItem(isUnlocked: true),
        ]
        subject = ProfileSwitcherState(
            alternateAccounts: alternates,
            currentAccountProfile: account1,
            isVisible: true
        )

        XCTAssertEqual(alternates + [account1], subject?.accounts)
    }

    /// Tests the init succeeds with accounts matching
    func test_init_currentAndAlternateAccounts_alternateAccountsMatch() {
        let account1 = ProfileSwitcherItem()
        let alternates = [
            ProfileSwitcherItem(isUnlocked: false),
            ProfileSwitcherItem(isUnlocked: true),
        ]
        subject = ProfileSwitcherState(
            alternateAccounts: alternates,
            currentAccountProfile: account1,
            isVisible: true
        )

        XCTAssertEqual(alternates, subject?.alternateAccounts)
    }

    /// Tests the init succeeds with current account matching
    func test_init_currentAndAlternateAccounts_currentProfilesMatch() {
        let account = ProfileSwitcherItem()
        let alternates = [
            ProfileSwitcherItem(isUnlocked: false),
            ProfileSwitcherItem(isUnlocked: true),
        ]
        subject = ProfileSwitcherState(
            alternateAccounts: alternates,
            currentAccountProfile: account,
            isVisible: true
        )

        XCTAssertEqual(account, subject?.currentAccountProfile)
    }

    /// Tests the select account with current account matching
    func test_selectAccount_currentProfilesMatch_secondUnlocked() {
        let unlocked = ProfileSwitcherItem(isUnlocked: true)
        let secondUnlocked = ProfileSwitcherItem(isUnlocked: true)
        let locked = ProfileSwitcherItem(isUnlocked: false)
        let accounts = [
            unlocked,
            secondUnlocked,
            locked,
        ]
        let current = ProfileSwitcherItem()
        subject = ProfileSwitcherState(
            alternateAccounts: accounts,
            currentAccountProfile: current,
            isVisible: true
        )
        subject?.selectAccount(secondUnlocked)

        XCTAssertEqual(secondUnlocked, subject?.currentAccountProfile)
    }

    /// Tests the select account with current account matching
    func test_selectAccount_currentProfilesMatch_locked() {
        let unlocked = ProfileSwitcherItem(isUnlocked: true)
        let secondUnlocked = ProfileSwitcherItem(isUnlocked: true)
        let locked = ProfileSwitcherItem(isUnlocked: false)
        let accounts = [
            unlocked,
            secondUnlocked,
            locked,
        ]
        let current = ProfileSwitcherItem()
        subject = ProfileSwitcherState(
            alternateAccounts: accounts,
            currentAccountProfile: current,
            isVisible: true
        )
        subject?.selectAccount(locked)

        XCTAssertEqual(locked, subject?.currentAccountProfile)
    }

    /// Tests the select account with current account matching
    func test_selectAccount_currentProfilesMatch_notFound() {
        let unlocked = ProfileSwitcherItem(isUnlocked: true)
        let secondUnlocked = ProfileSwitcherItem(isUnlocked: true)
        let locked = ProfileSwitcherItem(isUnlocked: false)
        let accounts = [
            unlocked,
            secondUnlocked,
            locked,
        ]
        let current = ProfileSwitcherItem()
        subject = ProfileSwitcherState(
            alternateAccounts: accounts,
            currentAccountProfile: current,
            isVisible: true
        )
        subject?.selectAccount(ProfileSwitcherItem(isUnlocked: true))

        XCTAssertEqual(current, subject?.currentAccountProfile)
    }

    /// Tests the select account with current has no change
    func test_selectAccount_currentProfile() {
        let unlocked = ProfileSwitcherItem(isUnlocked: true)
        let secondUnlocked = ProfileSwitcherItem(isUnlocked: true)
        let locked = ProfileSwitcherItem(isUnlocked: false)
        let accounts = [
            unlocked,
            secondUnlocked,
            locked,
        ]
        let current = ProfileSwitcherItem()
        subject = ProfileSwitcherState(
            alternateAccounts: accounts,
            currentAccountProfile: current,
            isVisible: true
        )
        subject?.selectAccount(current)

        XCTAssertEqual(current, subject?.currentAccountProfile)
    }
}
