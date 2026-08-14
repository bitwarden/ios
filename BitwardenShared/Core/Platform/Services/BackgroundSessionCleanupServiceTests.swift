import BackgroundTasks
import BitwardenKit
import BitwardenKitMocks
import TestHelpers
import XCTest

@testable import BitwardenShared
@testable import BitwardenSharedMocks

/// Note: the system delivers the background task handler a real, OS-constructed `BGAppRefreshTask`
/// instance, which can't be created in a unit test. `handleAppRefresh(_:)` — the purge → reschedule
/// → `setTaskCompleted` sequence — is therefore verified via manual/simulator testing rather than
/// here; these tests cover everything reachable without a live `BGAppRefreshTask`: registration and
/// the `scheduleNextRefresh()` scheduling math.
@MainActor
final class BackgroundSessionCleanupServiceTests: BitwardenTestCase {
    // MARK: Properties

    var authRepository: MockAuthRepository!
    var backgroundTaskScheduler: MockBackgroundTaskScheduler!
    var errorReporter: MockErrorReporter!
    var flightRecorder: MockFlightRecorder!
    var stateService: MockStateService!
    var subject: DefaultBackgroundSessionCleanupService!
    var timeProvider: MockTimeProvider!
    var vaultTimeoutService: MockVaultTimeoutService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

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

    override func tearDown() async throws {
        try await super.tearDown()

        authRepository = nil
        backgroundTaskScheduler = nil
        errorReporter = nil
        flightRecorder = nil
        stateService = nil
        subject = nil
        timeProvider = nil
        vaultTimeoutService = nil
    }

    // MARK: Tests

    /// `register()` registers the task handler with the correct identifier.
    func test_register() {
        backgroundTaskScheduler.registerReturnValue = true

        subject.register()

        XCTAssertEqual(
            backgroundTaskScheduler.registerReceivedArguments?.identifier,
            Constants.BackgroundTaskIdentifier.sessionKeyCleanup,
        )
        XCTAssertTrue(errorReporter.errors.isEmpty)
    }

    /// `register()` logs an error if registration fails.
    func test_register_failure() {
        backgroundTaskScheduler.registerReturnValue = false

        subject.register()

        XCTAssertEqual(
            errorReporter.errors as? [BackgroundSessionCleanupServiceError],
            [.registrationFailed],
        )
    }

    /// `register()` is a no-op when there's no background task scheduler (e.g. in an extension).
    func test_register_noScheduler() {
        subject = DefaultBackgroundSessionCleanupService(
            authRepository: authRepository,
            backgroundTaskScheduler: nil,
            errorReporter: errorReporter,
            flightRecorder: flightRecorder,
            stateService: stateService,
            timeProvider: timeProvider,
            vaultTimeoutService: vaultTimeoutService,
        )

        subject.register()

        XCTAssertFalse(backgroundTaskScheduler.registerCalled)
    }

    /// `scheduleNextRefresh()` cancels any previously pending request before submitting a new one.
    func test_scheduleNextRefresh_cancelsExistingRequest() async {
        stateService.accounts = [.fixture()]
        vaultTimeoutService.timeUntilSessionTimeoutResult[Account.fixture().profile.userId] = 600

        await subject.scheduleNextRefresh()

        XCTAssertEqual(
            backgroundTaskScheduler.cancelReceivedIdentifier,
            Constants.BackgroundTaskIdentifier.sessionKeyCleanup,
        )
    }

    /// `scheduleNextRefresh()` doesn't submit a new request when there are no accounts.
    func test_scheduleNextRefresh_noAccounts() async {
        stateService.accounts = []

        await subject.scheduleNextRefresh()

        XCTAssertFalse(backgroundTaskScheduler.submitCalled)
    }

    /// `scheduleNextRefresh()` doesn't submit a new request when every account's timeout value
    /// doesn't allow session key sharing (`.never`/`.onAppRestart`).
    func test_scheduleNextRefresh_noEligibleAccounts() async {
        let account = Account.fixture()
        stateService.accounts = [account]
        // `timeUntilSessionTimeoutResult` has no entry for this user, matching the real
        // implementation's `nil` return for `.never`/`.onAppRestart`.

        await subject.scheduleNextRefresh()

        XCTAssertFalse(backgroundTaskScheduler.submitCalled)
    }

    /// `scheduleNextRefresh()` submits a request anchored to the soonest known remaining time
    /// across eligible accounts.
    func test_scheduleNextRefresh_submitsWithSoonestRemaining() async throws {
        let account1 = Account.fixture(profile: .fixture(userId: "1"))
        let account2 = Account.fixture(profile: .fixture(userId: "2"))
        stateService.accounts = [account1, account2]
        vaultTimeoutService.timeUntilSessionTimeoutResult["1"] = 3600
        vaultTimeoutService.timeUntilSessionTimeoutResult["2"] = 1800

        await subject.scheduleNextRefresh()

        let request = try XCTUnwrap(backgroundTaskScheduler.submitReceivedTaskRequest as? BGAppRefreshTaskRequest)
        XCTAssertEqual(request.identifier, Constants.BackgroundTaskIdentifier.sessionKeyCleanup)
        XCTAssertEqual(request.earliestBeginDate, timeProvider.presentTime.addingTimeInterval(1800))
    }

    /// `scheduleNextRefresh()` clamps the next refresh interval to the 5-minute floor, even if the
    /// soonest remaining time is shorter.
    func test_scheduleNextRefresh_clampsToMinimumInterval() async throws {
        let account = Account.fixture()
        stateService.accounts = [account]
        vaultTimeoutService.timeUntilSessionTimeoutResult[account.profile.userId] = 30

        await subject.scheduleNextRefresh()

        let request = try XCTUnwrap(backgroundTaskScheduler.submitReceivedTaskRequest as? BGAppRefreshTaskRequest)
        XCTAssertEqual(
            request.earliestBeginDate,
            timeProvider.presentTime.addingTimeInterval(Constants.sessionKeyCleanupMinimumInterval),
        )
    }

    /// `scheduleNextRefresh()` falls back to the heartbeat interval when an eligible account has
    /// no known future timeout (already elapsed, soft-logged-out, or never unlocked this way).
    func test_scheduleNextRefresh_fallsBackWhenNoLiveCountdown() async throws {
        let account = Account.fixture()
        stateService.accounts = [account]
        vaultTimeoutService.timeUntilSessionTimeoutResult[account.profile.userId] = 0

        await subject.scheduleNextRefresh()

        let request = try XCTUnwrap(backgroundTaskScheduler.submitReceivedTaskRequest as? BGAppRefreshTaskRequest)
        XCTAssertEqual(
            request.earliestBeginDate,
            timeProvider.presentTime.addingTimeInterval(Constants.sessionKeyCleanupFallbackInterval),
        )
    }

    /// `scheduleNextRefresh()` treats an error from `timeUntilSessionTimeout` as an eligible
    /// account with an unknown countdown, rather than silently excluding it, and logs the error.
    func test_scheduleNextRefresh_timeUntilSessionTimeoutError() async throws {
        let account = Account.fixture()
        stateService.accounts = [account]
        vaultTimeoutService.timeUntilSessionTimeoutError = BitwardenTestError.example

        await subject.scheduleNextRefresh()

        let request = try XCTUnwrap(backgroundTaskScheduler.submitReceivedTaskRequest as? BGAppRefreshTaskRequest)
        XCTAssertEqual(
            request.earliestBeginDate,
            timeProvider.presentTime.addingTimeInterval(Constants.sessionKeyCleanupFallbackInterval),
        )
        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
    }

    /// `scheduleNextRefresh()` logs an error if submitting the request fails.
    func test_scheduleNextRefresh_submitError() async {
        let account = Account.fixture()
        stateService.accounts = [account]
        vaultTimeoutService.timeUntilSessionTimeoutResult[account.profile.userId] = 3600
        backgroundTaskScheduler.submitThrowableError = BitwardenTestError.example

        await subject.scheduleNextRefresh()

        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
    }

    /// `scheduleNextRefresh()` is a no-op when there's no background task scheduler (e.g. in an
    /// extension).
    func test_scheduleNextRefresh_noScheduler() async {
        subject = DefaultBackgroundSessionCleanupService(
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

        XCTAssertFalse(backgroundTaskScheduler.cancelCalled)
        XCTAssertFalse(backgroundTaskScheduler.submitCalled)
    }
}
