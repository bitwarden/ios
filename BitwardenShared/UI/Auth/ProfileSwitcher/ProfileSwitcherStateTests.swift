import XCTest

@testable import BitwardenShared

// MARK: - ProfileSwitcherStateTests

final class ProfileSwitcherStateTests: BitwardenTestCase {
    // MARK: Properties

    var subject: ProfileSwitcherState!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        subject = ProfileSwitcherState(accounts: [], activeAccountId: nil, isVisible: false)
    }

    override func tearDown() {
        super.tearDown()

        subject = nil
    }

    /// Tests the static empty var alternateAccounts
    func test_empty_accounts() {
        XCTAssertEqual(subject.accounts, [])
    }

    /// Tests the static empty var alternateAccounts
    func test_empty_alternateAccounts() {
        XCTAssertEqual(subject.alternateAccounts, [])
    }

    /// Tests the  empty active account
    func test_empty_currentAccount() {
        XCTAssertNil(subject.activeAccountId)
    }

    /// Setting the alternate accounts should succeed
    func test_empty_setAlternates_alternatesMatch() {
        let newAlternates = [
            ProfileSwitcherItem(),
        ]
        subject.accounts = newAlternates

        XCTAssertEqual(newAlternates, subject?.alternateAccounts)
    }

    /// Setting the active account id should yield an active account if the id matches an account
    func test_empty_setActiveAccountId_found() {
        let alternate = ProfileSwitcherItem()
        let newAccounts = [
            alternate,
        ]
        subject.accounts = newAccounts
        XCTAssertNil(subject.activeAccountId)
        XCTAssertEqual(newAccounts, subject.alternateAccounts)
        subject.activeAccountId = alternate.userId

        XCTAssertEqual(subject.activeAccountProfile, alternate)
        XCTAssertEqual([], subject.alternateAccounts)
    }

    /// Tests the current account initials when current account is empty
    func test_currentAccount_userInitials_empty() {
        XCTAssertEqual(subject.activeAccountInitials, "..")
    }

    /// Tests the current account initials when current account known
    func test_currentAccount_userInitials_nonEmpty() {
        let alternate = ProfileSwitcherItem(
            userInitials: "TC"
        )
        let newAccounts = [
            alternate,
        ]
        subject.accounts = newAccounts
        subject.activeAccountId = alternate.userId
        XCTAssertEqual(subject.activeAccountInitials, "TC")
    }

    /// Passing an active account id with no accounts yields no active account
    func test_init_noAccountsWithActive() {
        subject = ProfileSwitcherState(
            accounts: [],
            activeAccountId: "1",
            isVisible: false
        )

        XCTAssertNil(subject.activeAccountProfile)
    }

    /// Passing an account with no active id yields no active account
    func test_init_accountsWithoutActive() {
        let account = ProfileSwitcherItem()
        subject = ProfileSwitcherState(
            accounts: [account],
            activeAccountId: nil,
            isVisible: false
        )

        XCTAssertNil(subject.activeAccountProfile)
    }

    /// Passing an account and a matching active id yields an active account
    func test_init_accountsWithCurrent_accountsMatch() {
        let account = ProfileSwitcherItem()
        subject = ProfileSwitcherState(
            accounts: [account],
            activeAccountId: account.userId,
            isVisible: false
        )

        XCTAssertNotNil(subject.activeAccountProfile)
        XCTAssertEqual(subject.accounts, [account])
        XCTAssertEqual(subject.alternateAccounts, [])
    }

    /// Tests the init succeeds with current account matching
    func test_init_accountsWithCurrent_currentProfilesMatch() {
        let account = ProfileSwitcherItem()
        let alternate = ProfileSwitcherItem(isUnlocked: true)
        let accounts = [
            account,
            alternate,
        ]
        subject = ProfileSwitcherState(
            accounts: accounts,
            activeAccountId: account.userId,
            isVisible: true
        )

        XCTAssertNotNil(subject.activeAccountProfile)
        XCTAssertEqual(subject.accounts, accounts)
        XCTAssertEqual(subject.alternateAccounts, [alternate])
    }

    /// Tests `shouldSetAccessibilityFocus(for: )` responds to state and row type
    func test_shouldSetAccessibilityFocus_addAccount() {
        let account = ProfileSwitcherItem()
        let alternate = ProfileSwitcherItem(isUnlocked: false)
        let alternates = [
            alternate,
        ]
        subject = ProfileSwitcherState(
            accounts: [account] + alternates,
            activeAccountId: account.userId,
            isVisible: true
        )

        let shouldSet = subject?.shouldSetAccessibilityFocus(for: .addAccount)
        XCTAssertFalse(shouldSet!)
    }

    /// Tests `shouldSetAccessibilityFocus(for: )` responds to state and row type
    func test_shouldSetAccessibilityFocus_alternate() {
        let account = ProfileSwitcherItem()
        let alternate = ProfileSwitcherItem(isUnlocked: false)
        let alternates = [
            alternate,
        ]
        subject = ProfileSwitcherState(
            accounts: [account] + alternates,
            activeAccountId: account.userId,
            isVisible: true
        )

        let shouldSet = subject?.shouldSetAccessibilityFocus(for: .alternate(alternate))
        XCTAssertFalse(shouldSet!)
    }

    /// Tests `shouldSetAccessibilityFocus(for: )` responds to state and row type
    func test_shouldSetAccessibilityFocus_active_visibleAndHasNotSet() {
        let active = ProfileSwitcherItem()
        let alternate = ProfileSwitcherItem(isUnlocked: false)
        let alternates = [
            alternate,
        ]
        subject.accounts = [active] + alternates
        subject.activeAccountId = active.userId
        subject.isVisible = true

        let shouldSet = subject?.shouldSetAccessibilityFocus(for: .active(active))
        XCTAssertTrue(shouldSet!)
    }

    /// Tests `shouldSetAccessibilityFocus(for: )` responds to state and row type
    func test_shouldSetAccessibilityFocus_active_notVisibleAndHasNotSet() {
        let active = ProfileSwitcherItem()
        let alternate = ProfileSwitcherItem(isUnlocked: false)
        let alternates = [
            alternate,
        ]
        subject.accounts = [active] + alternates
        subject.activeAccountId = active.userId

        let shouldSet = subject?.shouldSetAccessibilityFocus(for: .active(active))
        XCTAssertFalse(shouldSet!)
    }

    /// Tests `shouldSetAccessibilityFocus(for: )` responds to state and row type
    func test_shouldSetAccessibilityFocus_active_visibleAndHasSet() {
        let active = ProfileSwitcherItem()
        let alternate = ProfileSwitcherItem(isUnlocked: false)
        let alternates = [
            alternate,
        ]
        subject.accounts = [active] + alternates
        subject.activeAccountId = active.userId
        subject.hasSetAccessibilityFocus = true

        let shouldSet = subject?.shouldSetAccessibilityFocus(for: .active(active))
        XCTAssertFalse(shouldSet!)
    }
}
