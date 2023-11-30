@testable import BitwardenShared
import XCTest

final class AccountProfileSwitcherTests: BitwardenTestCase {
    // MARK: Properties

    var vaultTimeoutService: MockVaultTimeoutService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        vaultTimeoutService = MockVaultTimeoutService()
    }

    override func tearDown() {
        super.tearDown()
        vaultTimeoutService = nil
    }

    func test_noRecord() async {
        vaultTimeoutService.timeoutStore = [:]
        let account = Account.fixtureAccountLogin()
        let result = await account.profileItem(vaultTimeoutService: vaultTimeoutService)
        let expectedResult = ProfileSwitcherItem(
            email: account.profile.email,
            isUnlocked: false,
            userId: account.profile.userId,
            userInitials: account.initials() ?? ".."
        )
        XCTAssertEqual(result, expectedResult)
        XCTAssertEqual(vaultTimeoutService.lockedIds, [account.profile.userId])
    }

    func test_known_locked() async {
        let account = Account.fixtureAccountLogin()
        vaultTimeoutService.timeoutStore = [account.profile.userId: true]
        let result = await account.profileItem(vaultTimeoutService: vaultTimeoutService)
        let expectedResult = ProfileSwitcherItem(
            email: account.profile.email,
            isUnlocked: false,
            userId: account.profile.userId,
            userInitials: account.initials() ?? ".."
        )
        XCTAssertEqual(result, expectedResult)
        XCTAssertEqual(vaultTimeoutService.lockedIds, [])
    }

    func test_known_unlocked() async {
        let account = Account.fixtureAccountLogin()
        vaultTimeoutService.timeoutStore = [account.profile.userId: false]
        let result = await account.profileItem(vaultTimeoutService: vaultTimeoutService)
        let expectedResult = ProfileSwitcherItem(
            email: account.profile.email,
            isUnlocked: true,
            userId: account.profile.userId,
            userInitials: account.initials() ?? ".."
        )
        XCTAssertEqual(result, expectedResult)
        XCTAssertEqual(vaultTimeoutService.lockedIds, [])
    }
}
