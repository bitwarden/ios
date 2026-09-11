import BackgroundTasks
import BitwardenKit
import BitwardenKitMocks
import TestHelpers
import Testing

@testable import BitwardenShared
@testable import BitwardenSharedMocks

/// Note: the system delivers the background task handler a real, OS-constructed `BGAppRefreshTask`
/// instance, which can't be created in a unit test. `handleAppRefresh(_:)` — the purge → reschedule
/// → `setTaskCompleted` sequence — is therefore verified via manual/simulator testing rather than
/// here; these tests cover everything reachable without a live `BGAppRefreshTask`: registration and
/// the `scheduleNextRefresh()` scheduling math.
@MainActor
struct BackgroundSessionCleanupServiceTests {
    // MARK: Properties

    let authRepository: MockAuthRepository
    let backgroundTaskScheduler: MockBackgroundTaskScheduler
    let errorReporter: MockErrorReporter
    let flightRecorder: MockFlightRecorder
    let stateService: MockStateService
    let subject: DefaultBackgroundSessionCleanupService
    let timeProvider: MockTimeProvider
    let vaultTimeoutService: MockVaultTimeoutService

    // MARK: Setup

    init() {
        authRepository = MockAuthRepository()
        backgroundTaskScheduler = MockBackgroundTaskScheduler()
        errorReporter = MockErrorReporter()
        flightRecorder = MockFlightRecorder()
        stateService = MockStateService()
        timeProvider = MockTimeProvider(.mockTime(Date(year: 2024, month: 1, day: 1)))
        vaultTimeoutService = MockVaultTimeoutService()

        subject = DefaultBackgroundSessionCleanupService(
            authRepository: authRepository,
            backgroundTaskScheduler: backgroundTaskScheduler,
            errorReporter: errorReporter,
            flightRecorder: flightRecorder,
            stateService: stateService,
            timeProvider: timeProvider,
            vaultTimeoutService: vaultTimeoutService,
        )
    }

    // MARK: Tests

    /// `register()` registers the task handler with the correct identifier.
    @Test
    func register() {
        backgroundTaskScheduler.registerReturnValue = true

        subject.register()

        #expect(
            backgroundTaskScheduler.registerReceivedArguments?.identifier
                == Constants.BackgroundTaskIdentifier.sessionKeyCleanup,
        )
        #expect(errorReporter.errors.isEmpty)
    }

    /// `register()` logs an error if registration fails.
    @Test
    func register_failure() {
        backgroundTaskScheduler.registerReturnValue = false

        subject.register()

        #expect(
            errorReporter.errors as? [BackgroundSessionCleanupServiceError]
                == [.registrationFailed],
        )
    }

    /// `register()` is a no-op when there's no background task scheduler (e.g. in an extension).
    @Test
    func register_noScheduler() {
        let subject = DefaultBackgroundSessionCleanupService(
            authRepository: authRepository,
            backgroundTaskScheduler: nil,
            errorReporter: errorReporter,
            flightRecorder: flightRecorder,
            stateService: stateService,
            timeProvider: timeProvider,
            vaultTimeoutService: vaultTimeoutService,
        )

        subject.register()

        #expect(!backgroundTaskScheduler.registerCalled)
    }

    /// `scheduleNextRefresh()` cancels any previously pending request before submitting a new one.
    @Test
    func scheduleNextRefresh_cancelsExistingRequest() async {
        stateService.accounts = [.fixture()]
        vaultTimeoutService.timeUntilSessionTimeoutResult[Account.fixture().profile.userId] = 600

        await subject.scheduleNextRefresh()

        #expect(
            backgroundTaskScheduler.cancelReceivedIdentifier
                == Constants.BackgroundTaskIdentifier.sessionKeyCleanup,
        )
    }

    /// `scheduleNextRefresh()` doesn't submit a new request when there are no accounts.
    @Test
    func scheduleNextRefresh_noAccounts() async {
        stateService.accounts = []

        await subject.scheduleNextRefresh()

        #expect(!backgroundTaskScheduler.submitCalled)
    }

    /// `scheduleNextRefresh()` doesn't submit a new request when every account's timeout value
    /// doesn't allow session key sharing (`.never`/`.onAppRestart`).
    @Test
    func scheduleNextRefresh_noEligibleAccounts() async {
        let account = Account.fixture()
        stateService.accounts = [account]
        // `timeUntilSessionTimeoutResult` has no entry for this user, matching the real
        // implementation's `nil` return for `.never`/`.onAppRestart`.

        await subject.scheduleNextRefresh()

        #expect(!backgroundTaskScheduler.submitCalled)
    }

    /// `scheduleNextRefresh()` submits a request anchored to the soonest known remaining time
    /// across eligible accounts.
    @Test
    func scheduleNextRefresh_submitsWithSoonestRemaining() async throws {
        let account1 = Account.fixture(profile: .fixture(userId: "1"))
        let account2 = Account.fixture(profile: .fixture(userId: "2"))
        stateService.accounts = [account1, account2]
        vaultTimeoutService.timeUntilSessionTimeoutResult["1"] = 3600
        vaultTimeoutService.timeUntilSessionTimeoutResult["2"] = 1800

        await subject.scheduleNextRefresh()

        let request = try #require(backgroundTaskScheduler.submitReceivedTaskRequest as? BGAppRefreshTaskRequest)
        #expect(request.identifier == Constants.BackgroundTaskIdentifier.sessionKeyCleanup)
        #expect(request.earliestBeginDate == timeProvider.presentTime.addingTimeInterval(1800))
    }

    /// `scheduleNextRefresh()` clamps the next refresh interval to the 5-minute floor, even if the
    /// soonest remaining time is shorter.
    @Test
    func scheduleNextRefresh_clampsToMinimumInterval() async throws {
        let account = Account.fixture()
        stateService.accounts = [account]
        vaultTimeoutService.timeUntilSessionTimeoutResult[account.profile.userId] = 30

        await subject.scheduleNextRefresh()

        let request = try #require(backgroundTaskScheduler.submitReceivedTaskRequest as? BGAppRefreshTaskRequest)
        #expect(
            request.earliestBeginDate
                == timeProvider.presentTime.addingTimeInterval(Constants.sessionKeyCleanupMinimumInterval),
        )
    }

    /// `scheduleNextRefresh()` falls back to the heartbeat interval when an eligible account has
    /// no known future timeout (already elapsed, soft-logged-out, or never unlocked this way).
    @Test
    func scheduleNextRefresh_fallsBackWhenNoLiveCountdown() async throws {
        let account = Account.fixture()
        stateService.accounts = [account]
        vaultTimeoutService.timeUntilSessionTimeoutResult[account.profile.userId] = 0

        await subject.scheduleNextRefresh()

        let request = try #require(backgroundTaskScheduler.submitReceivedTaskRequest as? BGAppRefreshTaskRequest)
        #expect(
            request.earliestBeginDate
                == timeProvider.presentTime.addingTimeInterval(Constants.sessionKeyCleanupFallbackInterval),
        )
    }

    /// `scheduleNextRefresh()` treats an error from `timeUntilSessionTimeout` as an eligible
    /// account with an unknown countdown, rather than silently excluding it, and logs the error.
    @Test
    func scheduleNextRefresh_timeUntilSessionTimeoutError() async throws {
        let account = Account.fixture()
        stateService.accounts = [account]
        vaultTimeoutService.timeUntilSessionTimeoutError = BitwardenTestError.example

        await subject.scheduleNextRefresh()

        let request = try #require(backgroundTaskScheduler.submitReceivedTaskRequest as? BGAppRefreshTaskRequest)
        #expect(
            request.earliestBeginDate
                == timeProvider.presentTime.addingTimeInterval(Constants.sessionKeyCleanupFallbackInterval),
        )
        #expect(errorReporter.errors as? [BitwardenTestError] == [.example])
    }

    /// `scheduleNextRefresh()` logs an error if submitting the request fails.
    @Test
    func scheduleNextRefresh_submitError() async {
        let account = Account.fixture()
        stateService.accounts = [account]
        vaultTimeoutService.timeUntilSessionTimeoutResult[account.profile.userId] = 3600
        backgroundTaskScheduler.submitThrowableError = BitwardenTestError.example

        await subject.scheduleNextRefresh()

        #expect(errorReporter.errors as? [BitwardenTestError] == [.example])
    }

    /// `scheduleNextRefresh()` is a no-op when there's no background task scheduler (e.g. in an
    /// extension).
    @Test
    func scheduleNextRefresh_noScheduler() async {
        let subject = DefaultBackgroundSessionCleanupService(
            authRepository: authRepository,
            backgroundTaskScheduler: nil,
            errorReporter: errorReporter,
            flightRecorder: flightRecorder,
            stateService: stateService,
            timeProvider: timeProvider,
            vaultTimeoutService: vaultTimeoutService,
        )
        stateService.accounts = [.fixture()]

        await subject.scheduleNextRefresh()

        #expect(!backgroundTaskScheduler.cancelCalled)
        #expect(!backgroundTaskScheduler.submitCalled)
    }
}
