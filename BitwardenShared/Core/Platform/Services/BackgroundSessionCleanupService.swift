import BackgroundTasks
import BitwardenKit
import Foundation

// MARK: - BackgroundSessionCleanupService

/// A service that registers, schedules, and executes a `BGAppRefreshTask` which purges expired
/// `.userSessionKey` Keychain items even if the app is never relaunched (e.g. a lost or stolen
/// device). This is defense-in-depth on top of, not a replacement for, the foreground
/// `AuthRepository.checkSessionTimeouts(isAppRestart:handleActiveUser:)` path — background task
/// execution is opportunistic and not guaranteed by the OS.
///
public protocol BackgroundSessionCleanupService: AnyObject { // sourcery: AutoMockable
    /// Registers the background app refresh task handler with the system. Must be called once,
    /// synchronously, before the app finishes launching.
    ///
    func register()

    /// Computes the next time the background task should fire, based on the current accounts'
    /// session timeout state, and (re-)submits a `BGAppRefreshTaskRequest` for it. Safe to call
    /// repeatedly; cancels any previously pending request for the same identifier first.
    ///
    func scheduleNextRefresh() async
}

// MARK: - BackgroundSessionCleanupServiceError

/// Errors thrown by `BackgroundSessionCleanupService`.
///
enum BackgroundSessionCleanupServiceError: Error {
    /// The background task failed to register with `BGTaskScheduler`.
    case registrationFailed
}

// MARK: - DefaultBackgroundSessionCleanupService

/// The default implementation of `BackgroundSessionCleanupService`.
///
class DefaultBackgroundSessionCleanupService: BackgroundSessionCleanupService {
    // MARK: Properties

    /// The repository used to purge expired `.userSessionKey` Keychain items.
    private let authRepository: AuthRepository

    /// The scheduler used to register and submit `BGTaskScheduler` requests, if the app isn't
    /// running in an extension.
    private let backgroundTaskScheduler: BackgroundTaskScheduler?

    /// The service used by the application to report non-fatal errors.
    private let errorReporter: ErrorReporter

    /// The service used by the application for recording temporary debug logs.
    private let flightRecorder: FlightRecorder

    /// The service used to enumerate the accounts on the device.
    private let stateService: StateService

    /// Provides the current time.
    private let timeProvider: TimeProvider

    /// The service used to determine each account's session timeout state.
    private let vaultTimeoutService: VaultTimeoutService

    // MARK: Initialization

    /// Creates a new `DefaultBackgroundSessionCleanupService`.
    ///
    /// - Parameters:
    ///   - authRepository: The repository used to purge expired `.userSessionKey` Keychain items.
    ///   - backgroundTaskScheduler: The scheduler used to register and submit `BGTaskScheduler`
    ///     requests, if the app isn't running in an extension.
    ///   - errorReporter: The service used by the application to report non-fatal errors.
    ///   - flightRecorder: The service used by the application for recording temporary debug logs.
    ///   - stateService: The service used to enumerate the accounts on the device.
    ///   - timeProvider: Provides the current time.
    ///   - vaultTimeoutService: The service used to determine each account's session timeout state.
    ///
    init(
        authRepository: AuthRepository,
        backgroundTaskScheduler: BackgroundTaskScheduler?,
        errorReporter: ErrorReporter,
        flightRecorder: FlightRecorder,
        stateService: StateService,
        timeProvider: TimeProvider,
        vaultTimeoutService: VaultTimeoutService,
    ) {
        self.authRepository = authRepository
        self.backgroundTaskScheduler = backgroundTaskScheduler
        self.errorReporter = errorReporter
        self.flightRecorder = flightRecorder
        self.stateService = stateService
        self.timeProvider = timeProvider
        self.vaultTimeoutService = vaultTimeoutService
    }

    // MARK: Methods

    func register() {
        guard let backgroundTaskScheduler else { return }
        let didRegister = backgroundTaskScheduler.register(
            forTaskWithIdentifier: Constants.BackgroundTaskIdentifier.sessionKeyCleanup,
            using: nil,
        ) { [weak self] task in
            guard let appRefreshTask = task as? BGAppRefreshTask else {
                task.setTaskCompleted(success: false)
                return
            }
            self?.handleAppRefresh(appRefreshTask)
        }
        if !didRegister {
            errorReporter.log(error: BackgroundSessionCleanupServiceError.registrationFailed)
        }
    }

    func scheduleNextRefresh() async {
        guard let backgroundTaskScheduler else { return }
        backgroundTaskScheduler.cancel(
            taskRequestWithIdentifier: Constants.BackgroundTaskIdentifier.sessionKeyCleanup,
        )

        // No account could ever produce a `.userSessionKey` without the main app running — safe
        // to stop rescheduling until the main app runs again (e.g. adding an account or changing
        // a timeout setting), which re-arms this via `scheduleNextRefresh()` on backgrounding.
        guard let interval = await nextRefreshInterval() else { return }

        let request = BGAppRefreshTaskRequest(identifier: Constants.BackgroundTaskIdentifier.sessionKeyCleanup)
        request.earliestBeginDate = timeProvider.presentTime.addingTimeInterval(interval)

        do {
            try backgroundTaskScheduler.submit(request)
        } catch {
            errorReporter.log(error: error)
        }
    }

    // MARK: Private

    /// Handles the system launching the background app refresh task: purges expired session
    /// keys, reschedules the next refresh, then marks the task complete.
    ///
    /// - Parameter task: The task instance provided by the system.
    ///
    private func handleAppRefresh(_ task: BGAppRefreshTask) {
        let work = Task {
            await flightRecorder.log("[BackgroundSessionCleanup] Background refresh task fired")
            await authRepository.purgeExpiredUserSessionKeys()
            await scheduleNextRefresh()
            await flightRecorder.log("[BackgroundSessionCleanup] Background refresh task completed")
            task.setTaskCompleted(success: true)
        }

        task.expirationHandler = { [weak self] in
            work.cancel()
            task.setTaskCompleted(success: false)
            Task {
                await self?.flightRecorder.log("[BackgroundSessionCleanup] Background refresh task expired")
            }
        }
    }

    /// Computes the interval from now until the background task should next fire.
    ///
    /// - Returns: The interval in seconds, clamped to the 5-minute floor, or `nil` if there are no
    ///   accounts that could ever need a future check — no accounts exist, or every account's
    ///   timeout value doesn't allow session key sharing (`.never`, `.onAppRestart`, `.immediately`).
    ///
    private func nextRefreshInterval() async -> TimeInterval? {
        let accounts = await (try? stateService.getAccounts()) ?? []

        var eligibleCount = 0
        var candidates: [TimeInterval] = []

        for account in accounts {
            let userId = account.profile.userId
            do {
                guard let remaining = try await vaultTimeoutService.timeUntilSessionTimeout(userId: userId) else {
                    // `nil` means this account's timeout value doesn't allow session key sharing
                    // — it can never need a future check.
                    continue
                }
                eligibleCount += 1
                if remaining > 0 {
                    candidates.append(remaining)
                }
            } catch {
                errorReporter.log(error: error)
                // Fail safe: treat as eligible with an unknown countdown rather than silently
                // excluding it from ever being rechecked.
                eligibleCount += 1
            }
        }

        guard eligibleCount > 0 else { return nil }

        // If any eligible account has no known future timeout (already elapsed, soft-logged-out,
        // or never unlocked this way), fall back to a heartbeat cadence — an extension could
        // create a fresh `.userSessionKey` for it at any time, with no way for us to predict when.
        if candidates.count < eligibleCount {
            candidates.append(Constants.sessionKeyCleanupFallbackInterval)
        }

        let interval = candidates.min() ?? Constants.sessionKeyCleanupFallbackInterval
        return max(interval, Constants.sessionKeyCleanupMinimumInterval)
    }
}
