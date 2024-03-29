import Combine
import XCTest

@testable import BitwardenShared

final class VaultTimeoutServiceTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: Properties

    var cancellables: Set<AnyCancellable>!
    var clientCrypto: MockClientCrypto!
    var keychainRepository: MockKeychainRepository!
    var stateService: MockStateService!
    var subject: DefaultVaultTimeoutService!
    var timeProvider: MockTimeProvider!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        cancellables = []
        clientCrypto = MockClientCrypto()
        keychainRepository = MockKeychainRepository()
        stateService = MockStateService()
        timeProvider = MockTimeProvider(
            .mockTime(
                .init(year: 2024, month: 1, day: 1)
            )
        )
        subject = DefaultVaultTimeoutService(
            clientCrypto: clientCrypto,
            keychainRepository: keychainRepository,
            stateService: stateService,
            timeProvider: timeProvider
        )
    }

    override func tearDown() {
        super.tearDown()

        cancellables = nil
        clientCrypto = nil
        keychainRepository = nil
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

    /// `isLocked(userId:)` should return true for a locked account.
    func test_isLocked_true() async {
        let account = Account.fixtureAccountLogin()
        subject.timeoutStore = [
            account.profile.userId: true,
        ]
        let isLocked = subject.isLocked(userId: account.profile.userId)
        XCTAssertTrue(isLocked)
    }

    /// `isLocked(userId:)` should return false for an unlocked account.
    func test_isLocked_false() async {
        let account = Account.fixtureAccountLogin()
        subject.timeoutStore = [
            account.profile.userId: false,
        ]
        let isLocked = subject.isLocked(userId: account.profile.userId)
        XCTAssertFalse(isLocked)
    }

    /// `isLocked(userId:)` should return true when no account is found.
    func test_isLocked_notFound() async {
        XCTAssertTrue(subject.isLocked(userId: "123"))
    }

    /// `lockVault(userId: nil)` should lock the active account.
    func test_lock_nil_active() async {
        let account = Account.fixtureAccountLogin()
        stateService.activeAccount = account
        stateService.accounts = [account]
        subject.timeoutStore = [:]
        await subject.lockVault(userId: nil)
        XCTAssertEqual(
            [
                account.profile.userId: true,
            ],
            subject.timeoutStore
        )
    }

    /// `lockVault(userId: nil)` should do nothing for no active account.
    func test_lock_nil_noActive() async {
        stateService.activeAccount = nil
        stateService.accounts = []
        subject.timeoutStore = [:]
        await subject.lockVault(userId: nil)
        XCTAssertEqual([:], subject.timeoutStore)
    }

    /// `lockVault(userId:)` should lock an unlocked account.
    func test_lock_unlocked() async {
        let account = Account.fixtureAccountLogin()
        stateService.accounts = [account]
        subject.timeoutStore = [
            account.profile.userId: false,
        ]
        await subject.lockVault(userId: account.profile.userId)
        XCTAssertEqual(
            [
                account.profile.userId: true,
            ],
            subject.timeoutStore
        )
    }

    /// `lockVault(userId:)` preserves the lock status of a locked account.
    func test_lock_locked() async {
        let account = Account.fixtureAccountLogin()
        stateService.accounts = [account]
        subject.timeoutStore = [
            account.profile.userId: true,
        ]
        await subject.lockVault(userId: account.profile.userId)
        XCTAssertEqual(
            [
                account.profile.userId: true,
            ],
            subject.timeoutStore
        )
    }

    /// `lockVault(userId:)` should lock an unknown account.
    func test_lock_notFound() async {
        let account = Account.fixtureAccountLogin()
        subject.timeoutStore = [:]
        stateService.accounts = [account]
        await subject.lockVault(userId: account.profile.userId)
        XCTAssertEqual(
            [
                account.profile.userId: true,
            ],
            subject.timeoutStore
        )
    }

    /// `remove(userId:)` should remove an unlocked account.
    func test_remove_unlocked() async {
        let account = Account.fixtureAccountLogin()
        stateService.accounts = [account]
        subject.timeoutStore = [
            account.profile.userId: false,
        ]
        await subject.remove(userId: account.profile.userId)
        XCTAssertTrue(subject.timeoutStore.isEmpty)
    }

    /// `remove(userId:)` should remove a locked account.
    func test_remove_locked() async {
        let account = Account.fixtureAccountLogin()
        stateService.accounts = [account]
        subject.timeoutStore = [
            account.profile.userId: true,
        ]
        await subject.remove(userId: account.profile.userId)
        XCTAssertTrue(subject.timeoutStore.isEmpty)
    }

    /// `remove(userId:)`preserves state when no account matches.
    func test_remove_notFound() async {
        let account = Account.fixtureAccountLogin()
        stateService.accounts = [account]
        subject.timeoutStore = [
            account.profile.userId: false,
        ]
        await subject.remove(userId: "123")
        XCTAssertEqual(
            [
                account.profile.userId: false,
            ],
            subject.timeoutStore
        )
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
        stateService.activeAccount = account
        stateService.accounts = [account]
        subject.timeoutStore = [:]
        try await subject.unlockVault(userId: nil)
        XCTAssertEqual(
            [
                account.profile.userId: false,
            ],
            subject.timeoutStore
        )
    }

    /// `unlockVault(userId: nil)` should do nothing for no active account.
    func test_unlock_nil_noActive() async throws {
        stateService.activeAccount = nil
        stateService.accounts = []
        subject.timeoutStore = [:]
        try await subject.unlockVault(userId: nil)
        XCTAssertEqual([:], subject.timeoutStore)
    }

    /// `unlockVault(userId:)` preserves the unlocked status of an unlocked account.
    func test_unlock_unlocked() async throws {
        let account = Account.fixtureAccountLogin()
        subject.timeoutStore = [
            account.profile.userId: false,
        ]
        try await subject.unlockVault(userId: account.profile.userId)
        XCTAssertEqual(
            [
                account.profile.userId: false,
            ],
            subject.timeoutStore
        )
    }

    /// `unlockVault(userId:)` should unlock a locked account.
    func test_unlock_locked() async throws {
        let account = Account.fixtureAccountLogin()
        stateService.accounts = [account]
        subject.timeoutStore = [
            account.profile.userId: true,
        ]
        try await subject.unlockVault(userId: account.profile.userId)
        XCTAssertEqual(
            [
                account.profile.userId: false,
            ],
            subject.timeoutStore
        )
    }

    /// `unlockVault(userId:)` should unlock an unknown account.
    func test_unlock_notFound() async throws {
        let account = Account.fixtureAccountLogin()
        stateService.accounts = [account]
        subject.timeoutStore = [:]
        try await subject.unlockVault(userId: account.profile.userId)
        XCTAssertEqual(
            [
                account.profile.userId: false,
            ],
            subject.timeoutStore
        )
    }

    /// `unlockVault(userId:)` keeps the previously unlocked vaults unlocked.
    func test_unlock_locksAlternates() async throws {
        let account = Account.fixtureAccountLogin()
        let alternate = Account.fixture(profile: .fixture(userId: "123"))
        let secondAlternate = Account.fixture(profile: .fixture(userId: "312"))
        stateService.accounts = [
            account,
            alternate,
            secondAlternate,
        ]
        subject.timeoutStore = [
            account.profile.userId: true,
            alternate.profile.userId: false,
            secondAlternate.profile.userId: true,
        ]
        try await subject.unlockVault(userId: account.profile.userId)

        let key = try await subject.keychainRepository.getUserAuthKeyValue(
            for: .neverLock(userId: account.profile.userId)
        )
        XCTAssertNotNil(key)
        XCTAssertEqual(
            [
                account.profile.userId: false,
                alternate.profile.userId: false,
                secondAlternate.profile.userId: true,
            ],
            subject.timeoutStore
        )
    }

    /// `unlockVault(userId:)` throws on a keychain error and unlocks the vault.
    func test_unlock_keychainError() async throws {
        let account = Account.fixture()
        let id = account.profile.userId

        stateService.activeAccount = account
        keychainRepository.setResult = .failure(KeychainServiceError.osStatusError(13))
        subject.timeoutStore = [id: true]

        await assertAsyncThrows(
            error: VaultTimeoutServiceError.setAuthKeyFailed
        ) {
            try await subject.unlockVault(userId: id)
        }
        XCTAssertEqual(subject.timeoutStore[id], false)
    }
}
