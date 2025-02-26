import BitwardenSdk
import Combine
import XCTest

@testable import BitwardenShared

final class VaultTimeoutServiceTests: BitwardenTestCase {
    // MARK: Properties

    var cancellables: Set<AnyCancellable>!
    var clientService: MockClientService!
    var errorReporter: MockErrorReporter!
    var stateService: MockStateService!
    var subject: DefaultVaultTimeoutService!
    var timeProvider: MockTimeProvider!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        cancellables = []
        clientService = MockClientService()
        errorReporter = MockErrorReporter()
        stateService = MockStateService()
        timeProvider = MockTimeProvider(
            .mockTime(
                .init(year: 2024, month: 1, day: 1)
            )
        )
        subject = DefaultVaultTimeoutService(
            clientService: clientService,
            errorReporter: errorReporter,
            stateService: stateService,
            timeProvider: timeProvider
        )
    }

    override func tearDown() {
        super.tearDown()

        cancellables = nil
        clientService = nil
        errorReporter = nil
        subject = nil
        stateService = nil
        timeProvider = nil
    }

    // MARK: Tests

    /// `.hasPassedSessionTimeout()` returns true if the user should be timed out.
    func test_hasPassedSessionTimeout() async throws {
        let account = Account.fixture()
        stateService.activeAccount = account
        stateService.vaultTimeout[account.profile.userId] = .fiveMinutes

        let currentTime = Date(year: 2024, month: 1, day: 2, hour: 6, minute: 0)
        timeProvider.timeConfig = .mockTime(currentTime)

        // Last active 4 minutes ago, no timeout.
        stateService.lastActiveTime[account.profile.userId] = Calendar.current
            .date(byAdding: .minute, value: -4, to: currentTime)
        var shouldTimeout = try await subject.hasPassedSessionTimeout(userId: account.profile.userId)
        XCTAssertFalse(shouldTimeout)

        // Last active 5 minutes ago, timeout.
        stateService.lastActiveTime[account.profile.userId] = Calendar.current
            .date(byAdding: .minute, value: -5, to: currentTime)
        shouldTimeout = try await subject.hasPassedSessionTimeout(userId: account.profile.userId)
        XCTAssertTrue(shouldTimeout)

        // Last active 6 minutes ago, timeout.
        stateService.lastActiveTime[account.profile.userId] = Calendar.current
            .date(byAdding: .minute, value: -6, to: currentTime)
        shouldTimeout = try await subject.hasPassedSessionTimeout(userId: account.profile.userId)
        XCTAssertTrue(shouldTimeout)

        // Last active in the distant past, timeout.
        stateService.lastActiveTime[account.profile.userId] = .distantPast
        shouldTimeout = try await subject.hasPassedSessionTimeout(userId: account.profile.userId)
        XCTAssertTrue(shouldTimeout)
    }

    /// `.hasPassedSessionTimeout()` returns false for a timeout value of app restart.
    func test_hasPassedSessionTimeout_appRestart() async throws {
        let account = Account.fixture()
        stateService.activeAccount = account
        stateService.lastActiveTime[account.profile.userId] = .distantPast
        stateService.vaultTimeout[account.profile.userId] = .onAppRestart

        let shouldTimeout = try await subject.hasPassedSessionTimeout(userId: account.profile.userId)
        XCTAssertFalse(shouldTimeout)
    }

    /// `.hasPassedSessionTimeout()` returns true if the user should be timed out for a custom timeout value.
    func test_hasPassedSessionTimeout_custom() async throws {
        let account = Account.fixture()
        stateService.activeAccount = account
        stateService.vaultTimeout[account.profile.userId] = .custom(120)

        let currentTime = Date(year: 2024, month: 1, day: 2, hour: 6, minute: 0)
        timeProvider.timeConfig = .mockTime(currentTime)

        // Last active 119 minutes ago, no timeout.
        stateService.lastActiveTime[account.profile.userId] = Calendar.current
            .date(byAdding: .minute, value: -119, to: currentTime)
        var shouldTimeout = try await subject.hasPassedSessionTimeout(userId: account.profile.userId)
        XCTAssertFalse(shouldTimeout)

        // Last active 120 minutes ago, timeout.
        stateService.lastActiveTime[account.profile.userId] = Calendar.current
            .date(byAdding: .minute, value: -120, to: currentTime)
        shouldTimeout = try await subject.hasPassedSessionTimeout(userId: account.profile.userId)
        XCTAssertTrue(shouldTimeout)

        // Last active 121 minutes ago, timeout.
        stateService.lastActiveTime[account.profile.userId] = Calendar.current
            .date(byAdding: .minute, value: -121, to: currentTime)
        shouldTimeout = try await subject.hasPassedSessionTimeout(userId: account.profile.userId)
        XCTAssertTrue(shouldTimeout)

        // Last active in the distant past, timeout.
        stateService.lastActiveTime[account.profile.userId] = .distantPast
        shouldTimeout = try await subject.hasPassedSessionTimeout(userId: account.profile.userId)
        XCTAssertTrue(shouldTimeout)
    }

    /// `.hasPassedSessionTimeout()` returns true if there's no last active time recorded for the user.
    func test_hasPassedSessionTimeout_noLastActiveTime() async throws {
        let account = Account.fixture()
        stateService.activeAccount = account
        stateService.vaultTimeout[account.profile.userId] = .fiveMinutes

        let shouldTimeout = try await subject.hasPassedSessionTimeout(userId: account.profile.userId)
        XCTAssertTrue(shouldTimeout)
    }

    /// `.hasPassedSessionTimeout()` returns false if the user's vault timeout value is negative.
    func test_hasPassedSessionTimeout_never() async throws {
        let account = Account.fixture()
        stateService.activeAccount = account
        stateService.lastActiveTime[account.profile.userId] = .distantPast
        stateService.vaultTimeout[account.profile.userId] = .never

        let shouldTimeout = try await subject.hasPassedSessionTimeout(userId: account.profile.userId)
        XCTAssertFalse(shouldTimeout)
    }

    /// `lockVault(userId:)` logs an error if one occurs.
    func test_lock_error() async {
        await subject.lockVault(userId: nil)
        XCTAssertEqual(errorReporter.errors as? [StateServiceError], [.noActiveAccount])
    }

    /// Tests that locking and unlocking the vault works correctly.
    func test_lock_unlock() async throws {
        let account = Account.fixtureAccountLogin()
        let userId = account.profile.userId

        try await subject.unlockVault(userId: userId, hadUserInteraction: false)
        XCTAssertFalse(subject.isLocked(userId: userId))

        await subject.lockVault(userId: userId)
        XCTAssertTrue(subject.isLocked(userId: userId))
    }

    /// `lockVault(userId:)` preserves the lock status of a previously locked account.
    func test_lock_previously_locked() async throws {
        let userId = "1"
        let user2Id = "2"

        try await subject.unlockVault(userId: user2Id, hadUserInteraction: false)

        XCTAssertTrue(subject.isLocked(userId: userId))
        XCTAssertFalse(subject.isLocked(userId: user2Id))

        await subject.lockVault(userId: user2Id)

        XCTAssertTrue(subject.isLocked(userId: userId))
        XCTAssertTrue(subject.isLocked(userId: user2Id))
    }

    /// `lockVault(userId:)` preserves the lock status of a previously unlocked account.
    func test_lock_previously_unlocked() async throws {
        let userId = "1"
        let user2Id = "2"

        try await subject.unlockVault(userId: userId, hadUserInteraction: false)
        try await subject.unlockVault(userId: user2Id, hadUserInteraction: false)

        await subject.lockVault(userId: user2Id)

        XCTAssertFalse(subject.isLocked(userId: userId))
        XCTAssertTrue(subject.isLocked(userId: user2Id))
    }

    /// `remove(userId:)` logs an error if one occurs.
    func test_remove_error() async {
        await subject.remove(userId: nil)
        XCTAssertEqual(errorReporter.errors as? [StateServiceError], [.noActiveAccount])
    }

    /// `remove(userId:)` should remove an unlocked account.
    func test_remove_unlocked() async throws {
        let userId = "1"
        clientService.userClientArray.updateValue(MockClient(), forKey: userId)
        try await subject.unlockVault(userId: userId, hadUserInteraction: false)

        XCTAssertFalse(subject.isLocked(userId: userId))
        XCTAssertNotNil(clientService.userClientArray[userId])

        await subject.remove(userId: userId)
        XCTAssertNil(clientService.userClientArray[userId])
    }

    /// `remove(userId:)` should remove a locked account.
    func test_remove_locked() async {
        let userId = "1"
        clientService.userClientArray.updateValue(MockClient(), forKey: userId)
        XCTAssertTrue(subject.isLocked(userId: userId))

        await subject.remove(userId: userId)
        XCTAssertNil(clientService.userClientArray[userId])
    }

    /// `remove(userId:)`preserves state when no account matches.
    func test_remove_notFound() async throws {
        let userId = "1"
        clientService.userClientArray.updateValue(MockClient(), forKey: userId)

        try await subject.unlockVault(userId: userId, hadUserInteraction: false)
        XCTAssertFalse(subject.isLocked(userId: userId))
        XCTAssertNotNil(clientService.userClientArray[userId])

        await subject.remove(userId: "random id")
        XCTAssertFalse(subject.isLocked(userId: userId))
        XCTAssertNotNil(clientService.userClientArray[userId])
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

    /// `unlockVault(userId: nil)` should unlock the active account.
    func test_unlock_nil_active() async throws {
        let account = Account.fixtureAccountLogin()
        let userId = account.profile.userId

        stateService.activeAccount = account
        clientService.userClientArray.updateValue(MockClient(), forKey: userId)

        await subject.lockVault(userId: userId)
        XCTAssertTrue(subject.isLocked(userId: userId))

        try await subject.unlockVault(userId: nil, hadUserInteraction: false)
        XCTAssertFalse(subject.isLocked(userId: userId))
    }

    /// `unlockVault(userId: nil)` should do nothing for no active account.
    func test_unlock_nil_noActive() async throws {
        let account = Account.fixtureAccountLogin()
        let userId = account.profile.userId

        stateService.activeAccount = nil
        stateService.accounts = []

        try await subject.unlockVault(userId: nil, hadUserInteraction: false)

        XCTAssertTrue(subject.isLocked(userId: userId))
    }

    /// `unlockVault(userId:hadUserInteraction:)` preserves the locked status of a locked account.
    func test_unlock_locked() async throws {
        let userId = "1"
        let user2Id = "2"

        XCTAssertTrue(subject.isLocked(userId: userId))

        try await subject.unlockVault(userId: user2Id, hadUserInteraction: true)
        XCTAssertTrue(subject.isLocked(userId: userId))
        XCTAssertFalse(subject.isLocked(userId: user2Id))
        XCTAssertTrue(stateService.setAccountHasBeenUnlockedInteractivelyHasBeenCalled)
    }

    /// `unlockVault(userId:hadUserInteraction:)` throws when setting account has been unlocked in current session.
    func test_unlock_locked_throws() async throws {
        let user2Id = "2"

        stateService.setAccountHasBeenUnlockedInteractivelyResult = .failure(BitwardenTestError.example)

        await assertAsyncThrows(error: BitwardenTestError.example) {
            try await subject.unlockVault(userId: user2Id, hadUserInteraction: true)
        }
    }

    /// `vaultLockStatusPublisher()` publishes the active user ID and whether their vault is locked.
    func test_vaultLockStatusPublisher() async throws {
        var publishedValues = [VaultLockStatus?]()
        let publisher = await subject.vaultLockStatusPublisher()
            .sink(receiveValue: { date in
                publishedValues.append(date)
            })
        defer { publisher.cancel() }

        stateService.activeIdSubject.send("1")
        try await subject.unlockVault(userId: "1", hadUserInteraction: false)
        stateService.activeIdSubject.send("2")
        try await subject.unlockVault(userId: "2", hadUserInteraction: false)
        await subject.lockVault(userId: "2")
        stateService.activeIdSubject.send(nil)

        XCTAssertEqual(
            publishedValues,
            [
                nil,
                VaultLockStatus(isVaultLocked: true, userId: "1"),
                VaultLockStatus(isVaultLocked: false, userId: "1"),
                VaultLockStatus(isVaultLocked: true, userId: "2"),
                VaultLockStatus(isVaultLocked: false, userId: "2"),
                VaultLockStatus(isVaultLocked: true, userId: "2"),
                nil,
            ]
        )
    }
}
