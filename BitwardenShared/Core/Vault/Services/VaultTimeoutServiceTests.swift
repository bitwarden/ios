import AuthenticatorBridgeKit
import AuthenticatorBridgeKitMocks
import BitwardenKitMocks
import BitwardenSdk
import Combine
import TestHelpers
import XCTest

@testable import BitwardenShared
@testable import BitwardenSharedMocks

@MainActor
final class VaultTimeoutServiceTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: Properties

    var biometricsRepository: MockBiometricsRepository!
    var cancellables: Set<AnyCancellable>!
    var clientService: MockClientService!
    var configService: MockConfigService!
    var errorReporter: MockErrorReporter!
    var sharedTimeoutService: MockSharedTimeoutService!
    var stateService: MockStateService!
    var subject: DefaultVaultTimeoutService!
    var timeProvider: MockTimeProvider!
    var userSessionStateService: MockUserSessionStateService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        biometricsRepository = MockBiometricsRepository()
        cancellables = []
        clientService = MockClientService()
        configService = MockConfigService()
        errorReporter = MockErrorReporter()
        sharedTimeoutService = MockSharedTimeoutService()
        stateService = MockStateService()
        timeProvider = MockTimeProvider(
            .mockTime(
                .init(year: 2024, month: 1, day: 1),
            ),
        )
        userSessionStateService = MockUserSessionStateService()
        userSessionStateService.getVaultTimeoutReturnValue = .fifteenMinutes
        userSessionStateService.getUnsuccessfulUnlockAttemptsReturnValue = 0

        subject = DefaultVaultTimeoutService(
            biometricsRepository: biometricsRepository,
            clientService: clientService,
            configService: configService,
            errorReporter: errorReporter,
            sharedTimeoutService: sharedTimeoutService,
            stateService: stateService,
            timeProvider: timeProvider,
            userSessionStateService: userSessionStateService,
        )
    }

    override func tearDown() async throws {
        try await super.tearDown()

        biometricsRepository = nil
        cancellables = nil
        clientService = nil
        configService = nil
        errorReporter = nil
        subject = nil
        stateService = nil
        timeProvider = nil
    }

    // MARK: Tests

    /// `.hasPassedSessionTimeout()` returns true if the user should be timed out using monotonic time.
    func test_hasPassedSessionTimeout() async throws {
        let account = Account.fixture()
        stateService.activeAccount = account
        userSessionStateService.getVaultTimeoutReturnValue = .fiveMinutes

        let currentTime = Date(year: 2024, month: 1, day: 2, hour: 6, minute: 0)
        let currentMonotonicTime: TimeInterval = 1000.0
        timeProvider.timeConfig = .mockTime(currentTime, currentMonotonicTime)

        // Last active 4 minutes ago (240 seconds), no timeout.
        userSessionStateService.getLastActiveTimeReturnValue = Calendar.current
            .date(byAdding: .minute, value: -4, to: currentTime)
        userSessionStateService.getLastActiveMonotonicTimeReturnValue = currentMonotonicTime - 240
        var shouldTimeout = try await subject.hasPassedSessionTimeout(userId: account.profile.userId)
        XCTAssertFalse(shouldTimeout)

        // Last active 5 minutes ago (300 seconds), timeout.
        userSessionStateService.getLastActiveTimeReturnValue = Calendar.current
            .date(byAdding: .minute, value: -5, to: currentTime)
        userSessionStateService.getLastActiveMonotonicTimeReturnValue = currentMonotonicTime - 300
        shouldTimeout = try await subject.hasPassedSessionTimeout(userId: account.profile.userId)
        XCTAssertTrue(shouldTimeout)

        // Last active 6 minutes ago (360 seconds), timeout.
        userSessionStateService.getLastActiveTimeReturnValue = Calendar.current
            .date(byAdding: .minute, value: -6, to: currentTime)
        userSessionStateService.getLastActiveMonotonicTimeReturnValue = currentMonotonicTime - 360
        shouldTimeout = try await subject.hasPassedSessionTimeout(userId: account.profile.userId)
        XCTAssertTrue(shouldTimeout)

        // Last active in the distant past, timeout.
        userSessionStateService.getLastActiveTimeReturnValue = .distantPast
        userSessionStateService.getLastActiveMonotonicTimeReturnValue = 0
        shouldTimeout = try await subject.hasPassedSessionTimeout(userId: account.profile.userId)
        XCTAssertTrue(shouldTimeout)
    }

    /// `.hasPassedSessionTimeout()` returns false for a timeout value of app restart when not restarting.
    func test_hasPassedSessionTimeout_appRestart_notRestarting() async throws {
        let account = Account.fixture()
        stateService.activeAccount = account
        userSessionStateService.getLastActiveTimeReturnValue = .distantPast
        userSessionStateService.getVaultTimeoutReturnValue = .onAppRestart

        let shouldTimeout = try await subject.hasPassedSessionTimeout(
            userId: account.profile.userId,
            isAppRestart: false,
        )
        XCTAssertFalse(shouldTimeout)
    }

    /// `.hasPassedSessionTimeout()` returns true for a timeout value of app restart when app is restarting.
    func test_hasPassedSessionTimeout_appRestart_isRestarting() async throws {
        let account = Account.fixture()
        stateService.activeAccount = account
        userSessionStateService.getLastActiveTimeReturnValue = .distantPast
        userSessionStateService.getVaultTimeoutReturnValue = .onAppRestart

        let shouldTimeout = try await subject.hasPassedSessionTimeout(
            userId: account.profile.userId,
            isAppRestart: true,
        )
        XCTAssertTrue(shouldTimeout)
    }

    /// `.hasPassedSessionTimeout()` returns true if the user should be timed out
    /// for a custom timeout value using monotonic time.
    func test_hasPassedSessionTimeout_custom() async throws {
        let account = Account.fixture()
        stateService.activeAccount = account
        userSessionStateService.getVaultTimeoutReturnValue = .custom(120)

        let currentTime = Date(year: 2024, month: 1, day: 2, hour: 6, minute: 0)
        let currentMonotonicTime: TimeInterval = 10000.0
        timeProvider.timeConfig = .mockTime(currentTime, currentMonotonicTime)

        // Last active 119 minutes ago (7140 seconds), no timeout.
        userSessionStateService.getLastActiveTimeReturnValue = Calendar.current
            .date(byAdding: .minute, value: -119, to: currentTime)
        userSessionStateService.getLastActiveMonotonicTimeReturnValue = currentMonotonicTime - 7140
        var shouldTimeout = try await subject.hasPassedSessionTimeout(userId: account.profile.userId)
        XCTAssertFalse(shouldTimeout)

        // Last active 120 minutes ago (7200 seconds), timeout.
        userSessionStateService.getLastActiveTimeReturnValue = Calendar.current
            .date(byAdding: .minute, value: -120, to: currentTime)
        userSessionStateService.getLastActiveMonotonicTimeReturnValue = currentMonotonicTime - 7200
        shouldTimeout = try await subject.hasPassedSessionTimeout(userId: account.profile.userId)
        XCTAssertTrue(shouldTimeout)

        // Last active 121 minutes ago (7260 seconds), timeout.
        userSessionStateService.getLastActiveTimeReturnValue = Calendar.current
            .date(byAdding: .minute, value: -121, to: currentTime)
        userSessionStateService.getLastActiveMonotonicTimeReturnValue = currentMonotonicTime - 7260
        shouldTimeout = try await subject.hasPassedSessionTimeout(userId: account.profile.userId)
        XCTAssertTrue(shouldTimeout)

        // Last active in the distant past, timeout.
        userSessionStateService.getLastActiveTimeReturnValue = .distantPast
        userSessionStateService.getLastActiveMonotonicTimeReturnValue = 0
        shouldTimeout = try await subject.hasPassedSessionTimeout(userId: account.profile.userId)
        XCTAssertTrue(shouldTimeout)
    }

    /// `.hasPassedSessionTimeout()` returns true if there's no last active time recorded for the user.
    func test_hasPassedSessionTimeout_noLastActiveTime() async throws {
        let account = Account.fixture()
        stateService.activeAccount = account
        userSessionStateService.getVaultTimeoutReturnValue = .fiveMinutes

        let shouldTimeout = try await subject.hasPassedSessionTimeout(userId: account.profile.userId)
        XCTAssertTrue(shouldTimeout)
    }

    /// `.hasPassedSessionTimeout()` returns false if the user's vault timeout value is negative.
    func test_hasPassedSessionTimeout_never() async throws {
        let account = Account.fixture()
        stateService.activeAccount = account
        userSessionStateService.getLastActiveTimeReturnValue = .distantPast
        userSessionStateService.getVaultTimeoutReturnValue = .never

        let shouldTimeout = try await subject.hasPassedSessionTimeout(userId: account.profile.userId)
        XCTAssertFalse(shouldTimeout)
    }

    /// `.hasPassedSessionTimeout()` detects device reboot and forces timeout when monotonic time is negative.
    func test_hasPassedSessionTimeout_rebootDetection() async throws {
        let account = Account.fixture()
        stateService.activeAccount = account
        userSessionStateService.getVaultTimeoutReturnValue = .fifteenMinutes

        let currentTime = Date(year: 2024, month: 1, day: 2, hour: 6, minute: 0)
        let currentMonotonicTime: TimeInterval = 100.0 // System rebooted, uptime is low
        timeProvider.timeConfig = .mockTime(currentTime, currentMonotonicTime)

        // Last active with a higher monotonic time than current (device was rebooted)
        userSessionStateService.getLastActiveTimeReturnValue = Calendar.current
            .date(byAdding: .minute, value: -2, to: currentTime)
        userSessionStateService.getLastActiveMonotonicTimeReturnValue = 5000.0 // Much higher than current

        let shouldTimeout = try await subject.hasPassedSessionTimeout(userId: account.profile.userId)
        // Should force timeout after reboot (safe approach)
        XCTAssertTrue(shouldTimeout)
    }

    /// `.hasPassedSessionTimeout()` falls back to wall-clock time when monotonic time
    /// is not available (migration scenario).
    func test_hasPassedSessionTimeout_migrationFallback() async throws {
        let account = Account.fixture()
        stateService.activeAccount = account
        userSessionStateService.getVaultTimeoutReturnValue = .fiveMinutes

        let currentTime = Date(year: 2024, month: 1, day: 2, hour: 6, minute: 0)
        timeProvider.timeConfig = .mockTime(currentTime, 1000.0)

        // Last active 4 minutes ago using wall-clock time, no monotonic time stored (migration scenario)
        userSessionStateService.getLastActiveTimeReturnValue = Calendar.current
            .date(byAdding: .minute, value: -4, to: currentTime)
        userSessionStateService.getLastActiveMonotonicTimeReturnValue = nil
        var shouldTimeout = try await subject.hasPassedSessionTimeout(userId: account.profile.userId)
        XCTAssertFalse(shouldTimeout)

        // Last active 5 minutes ago using wall-clock time, timeout
        userSessionStateService.getLastActiveTimeReturnValue = Calendar.current
            .date(byAdding: .minute, value: -5, to: currentTime)
        userSessionStateService.getLastActiveMonotonicTimeReturnValue = nil
        shouldTimeout = try await subject.hasPassedSessionTimeout(userId: account.profile.userId)
        XCTAssertTrue(shouldTimeout)

        // Last active 6 minutes ago using wall-clock time, timeout
        userSessionStateService.getLastActiveTimeReturnValue = Calendar.current
            .date(byAdding: .minute, value: -6, to: currentTime)
        userSessionStateService.getLastActiveMonotonicTimeReturnValue = nil
        shouldTimeout = try await subject.hasPassedSessionTimeout(userId: account.profile.userId)
        XCTAssertTrue(shouldTimeout)
    }

    /// `isPinUnlockAvailable` throws errors.
    func test_isPinUnlockAvailable_error() async throws {
        stateService.pinProtectedUserKeyEnvelopeError = BitwardenTestError.example
        await assertAsyncThrows(error: BitwardenTestError.example) {
            _ = try await subject.isPinUnlockAvailable(userId: "1")
        }
    }

    /// `isPinUnlockAvailable` returns `false` if the active user does not have a pin protected user
    /// key or pin protected user key envelope.
    func test_isPinUnlockAvailable_false() async throws {
        stateService.activeAccount = .fixture()
        stateService.pinProtectedUserKeyValue = ["1": "123"]

        let value = try await subject.isPinUnlockAvailable(userId: "1")
        XCTAssertTrue(value)
    }

    /// `isPinUnlockAvailable` returns `true` if the active user has a pin protected user key.
    func test_isPinUnlockAvailable_true_pinProtectedUserKey() async throws {
        stateService.activeAccount = .fixture()
        stateService.pinProtectedUserKeyValue = ["1": "123"]

        let value = try await subject.isPinUnlockAvailable(userId: "1")
        XCTAssertTrue(value)
    }

    /// `isPinUnlockAvailable` returns `true` if the active user has a pin protected user key envelope.
    func test_isPinUnlockAvailable_true_pinProtectedUserKeyEnvelope() async throws {
        stateService.activeAccount = .fixture()
        stateService.pinProtectedUserKeyEnvelopeValue = ["1": "123"]

        let value = try await subject.isPinUnlockAvailable(userId: "1")
        XCTAssertTrue(value)
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

    /// `sessionTimeoutAction()` returns the session timeout action for a user.
    func test_sessionTimeoutAction() async throws {
        stateService.activeAccount = .fixture(profile: .fixture(userId: "1"))
        stateService.accounts = [.fixture(profile: .fixture(userId: "2"))]
        stateService.timeoutAction["1"] = .lock
        stateService.timeoutAction["2"] = .logout

        var timeoutAction = try await subject.sessionTimeoutAction(userId: "1")
        XCTAssertEqual(timeoutAction, .lock)

        timeoutAction = try await subject.sessionTimeoutAction(userId: "2")
        XCTAssertEqual(timeoutAction, .logout)
    }

    /// `sessionTimeoutAction()` defaults to logout if the user doesn't have a master password and
    /// hasn't enabled pin or biometrics unlock.
    func test_sessionTimeoutAction_noMasterPassword() async throws {
        stateService.activeAccount = .fixture(profile: .fixture(userId: "1"))
        stateService.timeoutAction["1"] = .lock
        stateService.userHasMasterPassword["1"] = false

        let timeoutAction = try await subject.sessionTimeoutAction(userId: "1")
        XCTAssertEqual(timeoutAction, .logout)
        XCTAssertEqual(stateService.timeoutAction["1"], .logout)
    }

    /// `sessionTimeoutAction()` allows lock or logout if the user doesn't have a master password
    /// and has biometrics unlock enabled.
    func test_sessionTimeoutAction_noMasterPassword_biometricsEnabled() async throws {
        stateService.activeAccount = .fixture(profile: .fixture(userId: "1"))
        stateService.timeoutAction["1"] = .lock
        stateService.userHasMasterPassword["1"] = false
        biometricsRepository.getBiometricUnlockStatusByUserId["1"] = .available(.faceID, enabled: true)

        var timeoutAction = try await subject.sessionTimeoutAction(userId: "1")
        XCTAssertEqual(timeoutAction, .lock)

        stateService.timeoutAction["1"] = .logout
        timeoutAction = try await subject.sessionTimeoutAction(userId: "1")
        XCTAssertEqual(timeoutAction, .logout)
    }

    /// `sessionTimeoutAction()` allows lock or logout if the user doesn't have a master password
    /// and has pin unlock enabled.
    func test_sessionTimeoutAction_noMasterPassword_pinEnabled() async throws {
        stateService.activeAccount = .fixture(profile: .fixture(userId: "1"))
        stateService.pinProtectedUserKeyValue["1"] = "KEY"
        stateService.timeoutAction["1"] = .lock
        stateService.userHasMasterPassword["1"] = false

        var timeoutAction = try await subject.sessionTimeoutAction(userId: "1")
        XCTAssertEqual(timeoutAction, .lock)

        stateService.timeoutAction["1"] = .logout
        timeoutAction = try await subject.sessionTimeoutAction(userId: "1")
        XCTAssertEqual(timeoutAction, .logout)
    }

    /// `sessionTimeoutAction()` throws errors.
    func test_sessionTimeoutAction_error() async throws {
        stateService.userHasMasterPasswordError = BitwardenTestError.example
        await assertAsyncThrows(error: BitwardenTestError.example) {
            _ = try await subject.sessionTimeoutAction(userId: "1")
        }
    }

    /// `.setLastActiveTime(userId:)` sets the user's last active time and monotonic time.
    func test_setLastActiveTime() async throws {
        let account = Account.fixture()
        stateService.activeAccount = account
        let currentMonotonicTime: TimeInterval = 2500.0
        timeProvider.timeConfig = .mockTime(.now, currentMonotonicTime)

        try await subject.setLastActiveTime(userId: account.profile.userId)

        XCTAssertEqual(
            userSessionStateService.setLastActiveTimeReceivedArguments?.date,
            timeProvider.presentTime,
        )
        XCTAssertEqual(
            userSessionStateService.setLastActiveMonotonicTimeReceivedArguments?.monotonicTime,
            currentMonotonicTime,
        )
        XCTAssertEqual(sharedTimeoutService.clearTimeoutUserIds, ["1"])
    }

    /// `.setLastActiveTime(userId:)` clears shared timeout on a timeout of `.never` or `.onAppRestart`
    func test_setLastActiveTime_neverOrOnAppRestart() async throws {
        let account = Account.fixture()
        stateService.activeAccount = account
        userSessionStateService.getVaultTimeoutReturnValue = .never
        try await subject.setLastActiveTime(userId: account.profile.userId)
        XCTAssertEqual(sharedTimeoutService.clearTimeoutUserIds, ["1"])

        userSessionStateService.getVaultTimeoutReturnValue = .onAppRestart
        try await subject.setLastActiveTime(userId: account.profile.userId)
        XCTAssertEqual(sharedTimeoutService.clearTimeoutUserIds, ["1", "1"])
    }

    /// `.setLastActiveTime(userId:)` clears shared timeout if the user's action is `.lock`
    func test_setLastActiveTime_lock() async throws {
        let account = Account.fixture()
        stateService.activeAccount = account
        userSessionStateService.getVaultTimeoutReturnValue = .fifteenMinutes
        stateService.timeoutAction[account.profile.userId] = .lock

        try await subject.setLastActiveTime(userId: account.profile.userId)
        XCTAssertEqual(sharedTimeoutService.clearTimeoutUserIds, ["1"])
    }

    /// `.setLastActiveTime(userId:)` updates shared timeout if the user's action is `.logout`
    func test_setLastActiveTime_logout() async throws {
        let account = Account.fixture()
        stateService.activeAccount = account
        userSessionStateService.getVaultTimeoutReturnValue = .oneMinute
        stateService.timeoutAction[account.profile.userId] = .logout

        try await subject.setLastActiveTime(userId: account.profile.userId)
        XCTAssertEqual(sharedTimeoutService.clearTimeoutUserIds, [])
        XCTAssertEqual(sharedTimeoutService.updateTimeoutUserId, "1")
        XCTAssertEqual(sharedTimeoutService.updateTimeoutLastActiveDate, timeProvider.presentTime)
        XCTAssertEqual(sharedTimeoutService.updateTimeoutTimeoutLength, .oneMinute)
    }

    /// `.setLastActiveTime(userId:)` throws errors.
    func test_setLastActive_time_error() async throws {
        userSessionStateService.setLastActiveTimeThrowableError = BitwardenTestError.example

        await assertAsyncThrows(error: BitwardenTestError.example) {
            try await subject.setLastActiveTime(userId: "1")
        }
    }

    /// `.setVaultTimeout(value:userId:)` sets the user's vault timeout value.
    func test_setVaultTimeout() async throws {
        let account = Account.fixture()
        stateService.activeAccount = account
        try await subject.setVaultTimeout(value: .custom(120), userId: account.profile.userId)
        XCTAssertEqual(userSessionStateService.setVaultTimeoutReceivedArguments?.userId, account.profile.userId)
        XCTAssertEqual(userSessionStateService.setVaultTimeoutReceivedArguments?.value, .custom(120))
        XCTAssertEqual(sharedTimeoutService.clearTimeoutUserIds, ["1"])
    }

    /// `.setVaultTimeout(value:userId:)` sets the user's vault timeout value to on app restart.
    func test_setVaultTimeout_appRestart() async throws {
        let account = Account.fixture()
        stateService.activeAccount = account
        try await subject.setVaultTimeout(value: .onAppRestart, userId: account.profile.userId)
        XCTAssertEqual(userSessionStateService.setVaultTimeoutReceivedArguments?.userId, account.profile.userId)
        XCTAssertEqual(userSessionStateService.setVaultTimeoutReceivedArguments?.value, .onAppRestart)
        XCTAssertEqual(sharedTimeoutService.clearTimeoutUserIds, ["1"])
    }

    /// `.setVaultTimeout(value:userId:)` sets the user's vault timeout value to never.
    func test_setVaultTimeout_never() async throws {
        let account = Account.fixture()
        stateService.activeAccount = account
        try await subject.setVaultTimeout(value: .never, userId: account.profile.userId)
        XCTAssertEqual(userSessionStateService.setVaultTimeoutReceivedArguments?.userId, account.profile.userId)
        XCTAssertEqual(userSessionStateService.setVaultTimeoutReceivedArguments?.value, .never)
        XCTAssertEqual(sharedTimeoutService.clearTimeoutUserIds, ["1"])
    }

    /// `.setVaultTimeout(value:userId:)` clears shared timeout if the user's action is `.lock`
    func test_setVaultTimeout_lock() async throws {
        let account = Account.fixture()
        stateService.activeAccount = account
        stateService.timeoutAction[account.profile.userId] = .lock

        try await subject.setVaultTimeout(value: .oneMinute, userId: account.profile.userId)
        XCTAssertEqual(sharedTimeoutService.clearTimeoutUserIds, ["1"])
    }

    /// `.setVaultTimeout(value:userId:)` updates shared timeout if the user's action is `.logout`
    func test_setVaultTimeout_logout() async throws {
        let account = Account.fixture()
        stateService.activeAccount = account
        userSessionStateService.getLastActiveTimeReturnValue = timeProvider.presentTime
        stateService.timeoutAction[account.profile.userId] = .logout

        try await subject.setVaultTimeout(value: .oneMinute, userId: account.profile.userId)
        XCTAssertEqual(sharedTimeoutService.clearTimeoutUserIds, [])
        XCTAssertEqual(sharedTimeoutService.updateTimeoutUserId, "1")
        XCTAssertEqual(sharedTimeoutService.updateTimeoutLastActiveDate, timeProvider.presentTime)
        XCTAssertEqual(sharedTimeoutService.updateTimeoutTimeoutLength, .oneMinute)
    }

    /// `.setVaultTimeout(value:userId:)` throws errors.
    func test_setVaultTimeout_error() async throws {
        userSessionStateService.setVaultTimeoutThrowableError = BitwardenTestError.example

        await assertAsyncThrows(error: BitwardenTestError.example) {
            try await subject.setVaultTimeout(value: .fiveMinutes, userId: "1")
        }
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
            ],
        )
    }
} // swiftlint:disable:this file_length
