import XCTest

@testable import BitwardenShared

class SettingsRepositoryTests: BitwardenTestCase {
    // MARK: Properties

    var stateService: MockStateService!
    var subject: DefaultSettingsRepository!
    var syncService: MockSyncService!
    var vaultTimeoutService: MockVaultTimeoutService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        stateService = MockStateService()
        syncService = MockSyncService()
        vaultTimeoutService = MockVaultTimeoutService()

        subject = DefaultSettingsRepository(
            stateService: stateService,
            syncService: syncService,
            vaultTimeoutService: vaultTimeoutService
        )
    }

    override func tearDown() {
        super.tearDown()

        stateService = nil
        subject = nil
        syncService = nil
        vaultTimeoutService = nil
    }

    // MARK: Tests

    /// `fetchSync()` has the sync service perform a new sync.
    func test_fetchSync() async throws {
        try await subject.fetchSync()
        XCTAssertTrue(syncService.didFetchSync)
    }

    /// `fetchSync()` throws an error if syncing fails.
    func test_fetchSync_error() async throws {
        struct SyncError: Error, Equatable {}
        syncService.fetchSyncResult = .failure(SyncError())

        await assertAsyncThrows(error: SyncError()) {
            try await subject.fetchSync()
        }
    }

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

    /// `logout()` has the state service log the user out.
    func test_logout() async throws {
        stateService.activeAccount = .fixture(profile: .fixture(userId: "1"))

        try await subject.logout()

        XCTAssertEqual(stateService.accountsLoggedOut, ["1"])
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
}
