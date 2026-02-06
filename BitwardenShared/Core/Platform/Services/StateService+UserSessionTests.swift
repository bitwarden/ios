// swiftlint:disable:this file_name

import BitwardenKit
import BitwardenKitMocks
import XCTest

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - StateServiceUserSessionTests

class StateServiceUserSessionTests: BitwardenTestCase {
    // MARK: Properties

    var appSettingsStore: MockAppSettingsStore!
    var dataStore: DataStore!
    var errorReporter: MockErrorReporter!
    var keychainRepository: MockKeychainRepository!
    var userSessionKeychainRepository: MockUserSessionKeychainRepository!
    var subject: DefaultStateService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        appSettingsStore = MockAppSettingsStore()
        dataStore = DataStore(errorReporter: MockErrorReporter(), storeType: .memory)
        errorReporter = MockErrorReporter()
        keychainRepository = MockKeychainRepository()
        userSessionKeychainRepository = MockUserSessionKeychainRepository()

        subject = DefaultStateService(
            appSettingsStore: appSettingsStore,
            dataStore: dataStore,
            errorReporter: errorReporter,
            keychainRepository: keychainRepository,
            userSessionKeychainRepository: userSessionKeychainRepository,
        )
    }

    override func tearDown() {
        super.tearDown()

        appSettingsStore = nil
        dataStore = nil
        errorReporter = nil
        keychainRepository = nil
        subject = nil
        userSessionKeychainRepository = nil
    }

    // MARK: Last Active Time

    /// `getLastActiveTime(userId:)` gets the user's last active time.
    func test_getLastActiveTime() async throws {
        await subject.addAccount(.fixture(profile: .fixture(userId: "1")))

        let date = Date(timeIntervalSince1970: 1_234_567_890)
        userSessionKeychainRepository.getLastActiveTimeReturnValue = date
        let lastActiveTime = try await subject.getLastActiveTime(userId: "1")
        XCTAssertEqual(lastActiveTime, date)
    }

    /// `setLastActiveTime(userId:)` sets the user's last active time.
    func test_setLastActiveTime() async throws {
        await subject.addAccount(.fixture(profile: .fixture(userId: "1")))

        let date = Date(timeIntervalSince1970: 1_234_567_890)
        try await subject.setLastActiveTime(date, userId: "1")

        let actual = userSessionKeychainRepository.setLastActiveTimeReceivedArguments
        XCTAssertEqual(actual?.userId, "1")
        XCTAssertEqual(actual?.date, date)
    }

    // MARK: Last Active Monotonic Time

    /// `getLastActiveMonotonicTime(userId:)` returns the last active monotonic time for a user.
    func test_getLastActiveMonotonicTime() async throws {
        let account = Account.fixture()
        await subject.addAccount(account)

        let expectedMonotonicTime: TimeInterval = 12345.67
        userSessionKeychainRepository.getLastActiveMonotonicTimeReturnValue = expectedMonotonicTime

        let monotonicTime = try await subject.getLastActiveMonotonicTime(userId: account.profile.userId)
        XCTAssertEqual(monotonicTime, expectedMonotonicTime)
        XCTAssertEqual(userSessionKeychainRepository.getLastActiveMonotonicTimeReceivedUserId, account.profile.userId)
    }

    /// `getLastActiveMonotonicTime(userId:)` returns nil when no monotonic time is stored.
    func test_getLastActiveMonotonicTime_nil() async throws {
        let account = Account.fixture()
        await subject.addAccount(account)

        userSessionKeychainRepository.getLastActiveMonotonicTimeReturnValue = nil

        let monotonicTime = try await subject.getLastActiveMonotonicTime(userId: nil)
        XCTAssertNil(monotonicTime)
        XCTAssertEqual(userSessionKeychainRepository.getLastActiveMonotonicTimeReceivedUserId, account.profile.userId)
    }

    /// `getLastActiveMonotonicTime(userId:)` throws an error if there's no active account.
    func test_getLastActiveMonotonicTime_noActiveAccount() async throws {
        await assertAsyncThrows(error: StateServiceError.noActiveAccount) {
            _ = try await subject.getLastActiveMonotonicTime(userId: nil)
        }
    }

    /// `getLastSyncMonotonicTime(userId:)` returns the last sync monotonic time for a user.
    func test_getLastSyncMonotonicTime() async throws {
        let account = Account.fixture()
        await subject.addAccount(account)

        let expectedMonotonicTime: TimeInterval = 98765.43
        appSettingsStore.lastSyncMonotonicTimeByUserId[account.profile.userId] = expectedMonotonicTime

        let monotonicTime = try await subject.getLastSyncMonotonicTime(userId: account.profile.userId)
        XCTAssertEqual(monotonicTime, expectedMonotonicTime)
    }

    /// `getLastSyncMonotonicTime(userId:)` returns nil when no monotonic time is stored.
    func test_getLastSyncMonotonicTime_nil() async throws {
        let account = Account.fixture()
        await subject.addAccount(account)

        let monotonicTime = try await subject.getLastSyncMonotonicTime(userId: nil)
        XCTAssertNil(monotonicTime)
    }

    /// `getLastSyncMonotonicTime(userId:)` throws an error if there's no active account.
    func test_getLastSyncMonotonicTime_noActiveAccount() async throws {
        await assertAsyncThrows(error: StateServiceError.noActiveAccount) {
            _ = try await subject.getLastSyncMonotonicTime(userId: nil)
        }
    }

    // MARK: Unsuccessful Unlock Attempts

    /// `getUnsuccessfulUnlockAttempts(userId:)` gets the unsuccessful unlock attempts for the account.
    func test_getUnsuccessfulUnlockAttempts() async throws {
        await subject.addAccount(.fixture(profile: .fixture(userId: "1")))

        userSessionKeychainRepository.getUnsuccessfulUnlockAttemptsReturnValue = 4

        let unsuccessfulUnlockAttempts = try await subject.getUnsuccessfulUnlockAttempts(userId: "1")
        XCTAssertEqual(unsuccessfulUnlockAttempts, 4)
    }

    /// `getUnsuccessfulUnlockAttempts(userId:)` returns `0` if no value is stored.
    func test_getUnsuccessfulUnlockAttempts_default() async throws {
        let item = KeychainItem.unsuccessfulUnlockAttempts(userId: "1")
        let error = KeychainServiceError.keyNotFound(item)
        userSessionKeychainRepository.getUnsuccessfulUnlockAttemptsThrowableError = error

        await subject.addAccount(.fixture(profile: .fixture(userId: "1")))

        let unsuccessfulUnlockAttempts = try await subject.getUnsuccessfulUnlockAttempts(userId: "1")
        XCTAssertEqual(unsuccessfulUnlockAttempts, 0)
    }

    /// `setUnsuccessfulUnlockAttempts(userId:)` sets the unsuccessful unlock attempts for the account.
    func test_setUnsuccessfulUnlockAttempts() async throws {
        await subject.addAccount(.fixture(profile: .fixture(userId: "1")))

        try await subject.setUnsuccessfulUnlockAttempts(3, userId: "1")

        let actual = userSessionKeychainRepository.setUnsuccessfulUnlockAttemptsReceivedArguments
        XCTAssertEqual(actual?.userId, "1")
        XCTAssertEqual(actual?.attempts, 3)
    }

    // MARK: Vault Timeout

    /// `.getVaultTimeout(userId:)` gets the user's vault timeout.
    func test_getVaultTimeout() async throws {
        await subject.addAccount(.fixture(profile: .fixture(userId: "1")))

        try await subject.setVaultTimeout(.custom(20), userId: "1")
        let key = userSessionKeychainRepository.setVaultTimeoutReceivedArguments
        XCTAssertEqual(key?.minutes, 20)
        XCTAssertEqual(key?.userId, "1")

        userSessionKeychainRepository.getVaultTimeoutReturnValue = 20
        let vaultTimeout = try await subject.getVaultTimeout(userId: "1")
        XCTAssertEqual(vaultTimeout, .custom(20))
    }

    /// `.getVaultTimeout(userId:)` gets the default vault timeout for the user if a value isn't set.
    func test_getVaultTimeout_default() async throws {
        let item = KeychainItem.vaultTimeout(userId: "1")
        userSessionKeychainRepository.getVaultTimeoutThrowableError = KeychainServiceError.keyNotFound(item)

        await subject.addAccount(.fixture(profile: .fixture(userId: "1")))

        let vaultTimeout = try await subject.getVaultTimeout()
        XCTAssertEqual(vaultTimeout, .fifteenMinutes)
    }

    /// `.getVaultTimeout(userId:)` gets the user's vault timeout when it's set to never lock.
    func test_getVaultTimeout_neverLock() async throws {
        let item = KeychainItem.vaultTimeout(userId: "1")
        userSessionKeychainRepository.getVaultTimeoutThrowableError = KeychainServiceError.keyNotFound(item)
        keychainRepository.mockStorage[keychainRepository.formattedKey(for: .neverLock(userId: "1"))] = "NEVER_LOCK_KEY"

        await subject.addAccount(.fixture(profile: .fixture(userId: "1")))

        let vaultTimeout = try await subject.getVaultTimeout()
        XCTAssertEqual(vaultTimeout, .never)
    }

    /// `getVaultTimeout(userId:)` returns the default timeout if the user has a never lock value
    /// stored but the never lock key doesn't exist.
    func test_getVaultTimeout_neverLock_missingKey() async throws {
        appSettingsStore.vaultTimeout["1"] = -2

        await subject.addAccount(.fixture(profile: .fixture(userId: "1")))

        let vaultTimeout = try await subject.getVaultTimeout()
        XCTAssertEqual(vaultTimeout, .fifteenMinutes)
    }

    /// `.setVaultTimeout(value:userId:)` sets the vault timeout value for the user.
    func test_setVaultTimeout() async throws {
        await subject.addAccount(.fixture(profile: .fixture(userId: "1")))

        try await subject.setVaultTimeout(.custom(20))

        let key = userSessionKeychainRepository.setVaultTimeoutReceivedArguments
        XCTAssertEqual(key?.minutes, 20)
        XCTAssertEqual(key?.userId, "1")
    }
}
