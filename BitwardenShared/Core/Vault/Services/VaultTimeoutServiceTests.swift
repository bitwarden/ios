import BitwardenSdk
import Combine
import XCTest

@testable import BitwardenShared

final class VaultTimeoutServiceTests: BitwardenTestCase {
    // MARK: Properties

    var cancellables: Set<AnyCancellable>!
    var clientService: MockClientService!
    var stateService: MockStateService!
    var subject: DefaultVaultTimeoutService!
    var timeProvider: MockTimeProvider!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        cancellables = []
        clientService = MockClientService()
        stateService = MockStateService()
        timeProvider = MockTimeProvider(
            .mockTime(
                .init(year: 2024, month: 1, day: 1)
            )
        )
        subject = DefaultVaultTimeoutService(
            clientService: clientService,
            stateService: stateService,
            timeProvider: timeProvider
        )
    }

    override func tearDown() {
        super.tearDown()

        cancellables = nil
        clientService = nil
        subject = nil
        stateService = nil
        timeProvider = nil
    }

    // MARK: Tests

    /// `.hasPassedSessionTimeout()` returns false if the user should not be timed out.
    func test_hasPassedSessionTimeout_false() async throws {
        let account = Account.fixture()
        stateService.activeAccount = account
        stateService.lastActiveTime[account.profile.userId] = Date()
        stateService.vaultTimeout[account.profile.userId] = .custom(120)
        let shouldTimeout = try await subject.hasPassedSessionTimeout(userId: account.profile.userId)
        XCTAssertFalse(shouldTimeout)
    }

    /// `.hasPassedSessionTimeout()` returns false if the user's vault timeout value is negative.
    func test_hasPassedSessionTimeout_never() async throws {
        let account = Account.fixture()
        stateService.activeAccount = account
        stateService.lastActiveTime[account.profile.userId] = Date()
        stateService.vaultTimeout[account.profile.userId] = .never
        let shouldTimeout = try await subject.hasPassedSessionTimeout(userId: account.profile.userId)
        XCTAssertFalse(shouldTimeout)
    }

    /// `.hasPassedSessionTimeout()` returns true if the user should be timed out.
    func test_hasPassedSessionTimeout_true() async throws {
        let account = Account.fixture()
        stateService.activeAccount = account
        stateService.lastActiveTime[account.profile.userId] = .distantPast
        stateService.vaultTimeout[account.profile.userId] = .oneMinute
        let shouldTimeout = try await subject.hasPassedSessionTimeout(userId: account.profile.userId)
        XCTAssertTrue(shouldTimeout)
    }

    /// `isLocked(userId:)` should return true if the user has no client.
    func test_isLocked_true() {
        let account = Account.fixtureAccountLogin()
        let userId = account.profile.userId

        clientService.isLockedResult[userId] = true

        XCTAssertTrue(subject.isLocked(userId: userId))
    }

    /// `isLocked(userId:)` should return false if the user has a client.
    func test_isLocked_false() async throws {
        let account = Account.fixtureAccountLogin()
        let userId = account.profile.userId

        clientService.updateClientLockedStatus(userId: userId, isLocked: false)

        try await subject.unlockVault(userId: userId)
        XCTAssertFalse(subject.isLocked(userId: userId))
    }

    /// `lockVault(userId: nil)` should lock the active account.
    func test_lockVault() async {
        let account = Account.fixtureAccountLogin()
        let userId = account.profile.userId

        clientService.updateClientLockedStatus(userId: userId, isLocked: false)

        XCTAssertFalse(subject.isLocked(userId: userId))

        await subject.lockVault(userId: userId)
        XCTAssertTrue(subject.isLocked(userId: userId))
    }

    /// `lockVault(userId:)` should lock an unlocked account.
    func test_lock_unlocked() async {
        let account = Account.fixtureAccountLogin()
        let userId = account.profile.userId

        clientService.updateClientLockedStatus(userId: userId, isLocked: false)

        XCTAssertFalse(subject.isLocked(userId: userId))

        await subject.lockVault(userId: userId)
        XCTAssertTrue(subject.isLocked(userId: userId))
    }

    /// `lockVault(userId:)` preserves the lock status of a previously locked account.
    func test_lock_previously_locked() async {
        clientService.updateClientLockedStatus(userId: "1", isLocked: true)
        clientService.updateClientLockedStatus(userId: "2", isLocked: false)

        await subject.lockVault(userId: "2")

        XCTAssertTrue(subject.isLocked(userId: "1"))
        XCTAssertTrue(subject.isLocked(userId: "2"))
    }

    /// `lockVault(userId:)` preserves the lock status of a previously unlocked account.
    func test_lock_previously_unlocked() async {
        clientService.updateClientLockedStatus(userId: "1", isLocked: false)
        clientService.updateClientLockedStatus(userId: "2", isLocked: false)

        await subject.lockVault(userId: "2")

        XCTAssertFalse(subject.isLocked(userId: "1"))
        XCTAssertTrue(subject.isLocked(userId: "2"))
    }

    /// `remove(userId:)` should remove an unlocked account.
    func test_remove_unlocked() async {
        let account = Account.fixtureAccountLogin()
        let userId = account.profile.userId

        clientService.updateClientLockedStatus(userId: userId, isLocked: false)

        await subject.remove(userId: userId)

        XCTAssertTrue(clientService.removeClientCalled)
    }

    /// `remove(userId:)` should remove a locked account.
    func test_remove_locked() async {
        let account = Account.fixtureAccountLogin()
        let userId = account.profile.userId

        clientService.updateClientLockedStatus(userId: userId, isLocked: true)

        await subject.remove(userId: userId)

        XCTAssertTrue(clientService.removeClientCalled)
    }

    /// `remove(userId:)`preserves state when no account matches.
    func test_remove_notFound() async {
        let account = Account.fixtureAccountLogin()
        let userId = account.profile.userId

        clientService.updateClientLockedStatus(userId: userId, isLocked: true)

        await subject.remove(userId: "random id")

        XCTAssertTrue(subject.isLocked(userId: userId))
    }

    /// `.setLastActiveTime(userId:)` sets the user's last active time.
    func test_setLastActiveTime() async throws {
        let account = Account.fixture()
        stateService.activeAccount = account
        try await subject.setLastActiveTime(userId: account.profile.userId)
        XCTAssertEqual(
            stateService.lastActiveTime[account.profile.userId]!.timeIntervalSince1970,
            Date().timeIntervalSince1970,
            accuracy: 1.0
        )
    }

    /// `.setVaultTimeout(value:userId:)` sets the user's vault timeout value.
    func test_setVaultTimeout() async throws {
        let account = Account.fixture()
        stateService.activeAccount = account
        try await subject.setVaultTimeout(value: .custom(120), userId: account.profile.userId)
        XCTAssertEqual(stateService.vaultTimeout[account.profile.userId], .custom(120))
    }

    /// `.setVaultTimeout(value:userId:)` sets the user's vault timeout value to on app restart.
    func test_setVaultTimeout_appRestart() async throws {
        let account = Account.fixture()
        stateService.activeAccount = account
        try await subject.setVaultTimeout(value: .onAppRestart, userId: account.profile.userId)
        XCTAssertEqual(stateService.vaultTimeout[account.profile.userId], .onAppRestart)
    }

    /// `.setVaultTimeout(value:userId:)` sets the user's vault timeout value to never.
    func test_setVaultTimeout_never() async throws {
        let account = Account.fixture()
        stateService.activeAccount = account
        try await subject.setVaultTimeout(value: .never, userId: account.profile.userId)
        XCTAssertEqual(stateService.vaultTimeout[account.profile.userId], .never)
    }

    /// `unlockVault(userId: nil)` should unock the active account.
    func test_unlock_nil_active() async throws {
        let account = Account.fixtureAccountLogin()
        let userId = account.profile.userId

        stateService.activeAccount = account
        stateService.accounts = [account]

        clientService.updateClientLockedStatus(userId: userId, isLocked: true)

        try await subject.unlockVault(userId: nil)

        XCTAssertFalse(subject.isLocked(userId: userId))
    }

    /// `unlockVault(userId: nil)` should do nothing for no active account.
    func test_unlock_nil_noActive() async throws {
        let account = Account.fixtureAccountLogin()
        let userId = account.profile.userId

        clientService.updateClientLockedStatus(userId: userId, isLocked: true)
        stateService.activeAccount = nil
        stateService.accounts = []

        try await subject.unlockVault(userId: nil)

        XCTAssertTrue(clientService.isLocked(userId: userId))
    }

    /// `unlockVault(userId:)` preserves the unlocked status of an unlocked account.
    func test_unlock_unlocked() async throws {
        clientService.updateClientLockedStatus(userId: "1", isLocked: true)
        clientService.updateClientLockedStatus(userId: "2", isLocked: false)

        try await subject.unlockVault(userId: "1")

        XCTAssertFalse(subject.isLocked(userId: "1"))
        XCTAssertFalse(subject.isLocked(userId: "2"))
    }

    /// `unlockVault(userId:)` should unlock a locked account.
    func test_unlock_locked() async throws {
        clientService.updateClientLockedStatus(userId: "1", isLocked: false)

        try await subject.unlockVault(userId: "1")

        XCTAssertFalse(subject.isLocked(userId: "1"))
    }
}
