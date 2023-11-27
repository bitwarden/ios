import XCTest

@testable import BitwardenShared

class SettingsRepositoryTests: BitwardenTestCase {
    // MARK: Properties

    var stateService: MockStateService!
    var subject: DefaultSettingsRepository!
    var vaultTimeoutService: MockVaultTimeoutService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        stateService = MockStateService()
        vaultTimeoutService = MockVaultTimeoutService()

        subject = DefaultSettingsRepository(stateService: stateService, vaultTimeoutService: vaultTimeoutService)
    }

    override func tearDown() {
        super.tearDown()

        stateService = nil
        subject = nil
    }

    // MARK: Tests

    /// `lockVault(userId:)` passes a user id to be locked.
    func test_lockVault_unknownUserId() {
        let task = Task {
            await subject.lockVault(userId: nil)
        }
        waitFor(!vaultTimeoutService.lockedIds.isEmpty)
        task.cancel()
        XCTAssertEqual(vaultTimeoutService.lockedIds, [nil])
    }

    /// `lockVault(userId:)` passes a user id to be locked.
    func test_lockVault_knownUserId() {
        let task = Task {
            await subject.lockVault(userId: "123")
        }
        waitFor(!vaultTimeoutService.lockedIds.isEmpty)
        task.cancel()
        XCTAssertEqual(vaultTimeoutService.lockedIds, ["123"])
    }

    /// `unlockVault(userId:)` passes a user id to be unlocked.
    func test_unlockVault_unknownUserId() {
        let task = Task {
            await subject.unlockVault(userId: nil)
        }
        waitFor(!vaultTimeoutService.unlockedIds.isEmpty)
        task.cancel()
        XCTAssertEqual(vaultTimeoutService.unlockedIds, [nil])
    }

    /// `unlockVault(userId:)` passes a user id to be unlocked.
    func test_unlockVault_knownUserId() {
        let task = Task {
            await subject.unlockVault(userId: "123")
        }
        waitFor(!vaultTimeoutService.unlockedIds.isEmpty)
        task.cancel()
        XCTAssertEqual(vaultTimeoutService.unlockedIds, ["123"])
    }

    /// `logout()` has the state service log the user out.
    func test_logout() async throws {
        stateService.activeAccount = .fixture(profile: .fixture(userId: "1"))

        try await subject.logout()

        XCTAssertEqual(stateService.accountsLoggedOut, ["1"])
    }
}
