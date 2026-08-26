import BitwardenKit
import Combine
import Foundation

// swiftlint:disable file_length

// MARK: - BillingService

/// A protocol for a service used to manage billing operations.
///
protocol BillingService: AnyObject { // sourcery: AutoMockable
    /// The callback URL scheme used by the Stripe checkout web authentication session.
    var checkoutCallbackUrlScheme: String { get }

    /// Creates a checkout session for Premium upgrade and returns the checkout URL.
    ///
    /// - Returns: A validated HTTPS URL for the checkout session.
    /// - Throws: `BillingError.invalidCheckoutUrl` if the URL is invalid or not HTTPS.
    ///
    func createCheckoutSession() async throws -> URL

    /// Creates a customer portal session for managing the Premium subscription.
    ///
    /// - Returns: A validated HTTPS URL for the customer portal.
    /// - Throws: `BillingError.invalidPortalUrl` if the URL is not HTTPS.
    ///
    func getPortalUrl() async throws -> URL

    /// Gets the Premium subscription plan details.
    ///
    /// - Returns: A `PremiumPlanResponseModel` containing the Premium plan details.
    ///
    func getPremiumPlan() async throws -> PremiumPlanResponseModel

    /// Gets the user's subscription details.
    ///
    /// - Returns: A `PremiumSubscription` containing the flattened subscription details.
    ///
    func getSubscription() async throws -> PremiumSubscription

    /// Notifies that the user canceled the Stripe checkout without completing payment, and
    /// publishes a `.canceled` status update.
    ///
    func premiumCheckoutCanceled()

    /// A publisher that emits the status of the Premium checkout sync process.
    ///
    func premiumCheckoutStatusPublisher() -> AnyPublisher<PremiumCheckoutStatus, Never>

    /// Returns whether the current environment is effectively self-hosted for Premium upgrade checks.
    /// Returns `false` when the debug override flag is enabled, regardless of the actual region.
    ///
    func isSelfHosted() async -> Bool

    /// Notifies that a Premium status change was detected via push notification, unrelated to
    /// any specific local checkout attempt. Triggers a forced sync to pick up the change, and
    /// sets the "Upgraded to Premium" card visible and publishes `.confirmed` if the active
    /// account is Premium afterward.
    ///
    func premiumStatusChanged() async

    /// Gets the current Premium upgrade pending state for the active account.
    ///
    /// - Returns: The current `PremiumUpgradePendingState`.
    ///
    func premiumUpgradePendingState() async -> PremiumUpgradePendingState

    /// A publisher that emits the Premium upgrade pending state for the active account.
    ///
    func premiumUpgradePendingStatePublisher() -> AnyPublisher<PremiumUpgradePendingState, Never>

    /// Confirms whether a just-succeeded Stripe checkout has been granted Premium yet, syncing
    /// to check and publishing checkout status updates as it resolves.
    ///
    func reconcileCheckoutSuccess() async

    /// Fetches the current subscription status and updates the visibility of the subscription
    /// attention action card.
    ///
    /// This runs for all non-self-hosted accounts regardless of their current premium status.
    /// A user whose subscription has lapsed (e.g. unpaid after repeated payment failures) still
    /// needs their payment-problem state surfaced even though the server reports them as
    /// non-premium. Accounts with no personal subscription (free users) receive a
    /// `GetSubscriptionRequestError` and are handled silently — the card is hidden for them.
    ///
    /// - Parameters:
    ///   - subscription: A previously fetched subscription to use, or `nil` to fetch fresh.
    ///
    func refreshSubscriptionAttentionCard(subscription: PremiumSubscription?) async

    /// Sets the "Upgraded to Premium" action card as dismissed and clears its visibility flag.
    ///
    func setUpgradedToPremiumActionCardDismissed() async

    /// Gets whether the subscription attention action card should be shown for the active account.
    ///
    /// - Returns: Whether the action card should be shown.
    ///
    func shouldShowSubscriptionAttentionCard() async -> Bool

    /// Gets whether the "Upgraded to Premium" action card should be shown for the active account.
    ///
    /// - Returns: Whether the action card should be shown.
    ///
    func shouldShowUpgradedToPremiumActionCard() async -> Bool

    /// Starts observing sync completions so a pending Premium upgrade can be resolved by any
    /// successful sync, not just the one that originated the upgrade attempt. Should be called
    /// once, for the lifetime of the app.
    ///
    func start() async
}

// MARK: - DefaultBillingService

/// The default implementation of `BillingService`.
///
class DefaultBillingService: BillingService { // swiftlint:disable:this type_body_length
    // MARK: - CheckoutSuccessSync

    /// The account, and state, of `reconcileCheckoutSuccess()`'s most recently forced sync.
    private enum CheckoutSuccessSync {
        /// The forced sync for `userId` is still in flight; its last-sync-time value isn't yet
        /// knowable.
        case inFlight(userId: String?)

        /// The forced sync for `userId` finished, persisting `syncTime` as the account's
        /// last-sync time (`nil` if reading it back failed).
        case resolved(userId: String?, syncTime: Date?)
    }

    // MARK: Properties

    /// The task that watches for active-account changes and re-subscribes
    /// `syncCompletionSubscriber` accordingly.
    private var activeAccountSubscriber: Task<Void, Never>?

    /// The API service used for billing requests.
    private let billingAPIService: BillingAPIService

    /// The service used to manage the app's billing state.
    private let billingStateService: BillingStateService

    let checkoutCallbackUrlScheme = "bitwarden"

    /// The state of `reconcileCheckoutSuccess()`'s most recently forced sync.
    ///
    /// Set to `.inFlight` right before that forced sync starts, covering the window while the
    /// sync is still in flight — including before it's known whether a later step in that same
    /// sync throws — during which its own last-sync-time write isn't yet knowable here. Updated
    /// to `.resolved` once the sync returns, additionally covering `reconcileOnEachNewSync(userId:)`
    /// observing that same write only *after* `reconcileCheckoutSuccess()` has already finished
    /// resolving `lastAttemptFailed` for it: these are two independently scheduled tasks, so
    /// nothing guarantees the former runs before the latter completes. Never explicitly cleared —
    /// a later, genuinely different sync produces a different last-sync-time value, so it's
    /// never matched by either check regardless of timing, without needing a "clear" that could
    /// itself race a legitimate, unrelated reconcile.
    ///
    /// Written from `reconcileCheckoutSuccess()` (UI-driven) and read from `reconcileOnEachNewSync(userId:)`'s
    /// background `Task`, with no lock or actor isolation between them — a real data race by
    /// Swift's memory model, invisible to the compiler since `DefaultBillingService` is a plain
    /// class, not `Sendable`-checked or actor-isolated. Investigated under Thread Sanitizer across
    /// this file's full suite, including a test built specifically to force the two contexts to
    /// race on this property (`reconcileCheckoutSuccess_suppressesConcurrentReconcileForOwnSync`);
    /// no race was ever observed. Left as-is given that evidence — revisit (e.g. isolate this
    /// property, or promote the class to an `actor` as `DefaultAuthenticatorSyncService` does for
    /// the same shape of state) if it turns out to matter.
    private var checkoutSuccessSync: CheckoutSuccessSync?

    /// The service used to manage feature flags.
    private let configService: ConfigService

    /// The debounce interval applied to the Premium checkout status publisher.
    private let debounceInterval: DispatchQueue.SchedulerTimeType.Stride

    /// The service used to manage the app's environment URLs.
    private let environmentService: EnvironmentService

    /// The service used by the application to report non-fatal errors.
    private let errorReporter: ErrorReporter

    /// Subject that emits the Premium checkout sync status.
    private let premiumCheckoutStatusSubject = CurrentValueSubject<PremiumCheckoutStatus?, Never>(nil)

    /// Subject that emits the Premium upgrade pending state.
    private let premiumUpgradePendingStateSubject = CurrentValueSubject<PremiumUpgradePendingState, Never>(
        PremiumUpgradePendingState(isPending: false, lastAttemptFailed: false),
    )

    /// Whether `start()` has already been called, to guard against subscribing more than once.
    private var started = false

    /// The service used to manage the app's state.
    private let stateService: StateService

    /// The task that watches for sync completions for the currently active account, to
    /// reconcile a pending Premium upgrade if one exists.
    private var syncCompletionSubscriber: Task<Void, Never>?

    /// The service used to handle syncing vault data with the API.
    private let syncService: SyncService

    // MARK: Initialization

    /// Creates a new `DefaultBillingService`.
    ///
    /// - Parameters:
    ///   - billingAPIService: The API service used for billing requests.
    ///   - billingStateService: The service used to manage the app's billing state.
    ///   - configService: The service used to manage feature flags.
    ///   - environmentService: The service used to manage the app's environment URLs.
    ///   - errorReporter: The service used to report non-fatal errors.
    ///   - stateService: The service used to query premium account status.
    ///   - syncService: The service used to handle syncing vault data with the API.
    ///   - debounceInterval: The debounce interval for the status publisher. Defaults to
    ///     `Constants.premiumCheckoutStatusDebounceInterval`.
    ///
    init(
        billingAPIService: BillingAPIService,
        billingStateService: BillingStateService,
        configService: ConfigService,
        environmentService: EnvironmentService,
        errorReporter: ErrorReporter,
        stateService: StateService,
        syncService: SyncService,
        debounceInterval: DispatchQueue.SchedulerTimeType.Stride = Constants.premiumCheckoutStatusDebounceInterval,
    ) {
        self.billingAPIService = billingAPIService
        self.billingStateService = billingStateService
        self.configService = configService
        self.environmentService = environmentService
        self.errorReporter = errorReporter
        self.stateService = stateService
        self.syncService = syncService
        self.debounceInterval = debounceInterval
    }

    // MARK: Methods

    func createCheckoutSession() async throws -> URL {
        let response = try await billingAPIService.createCheckoutSession()
        let url = response.checkoutSessionUrl
        // Ensure the checkout URL uses HTTPS to prevent man-in-the-middle attacks
        // when redirecting users to the payment provider.
        guard url.scheme == "https" else {
            throw BillingError.invalidCheckoutUrl
        }

        return url
    }

    func getPortalUrl() async throws -> URL {
        let response = try await billingAPIService.getPortalUrl()
        let url = response.url
        guard url.scheme == "https" else {
            throw BillingError.invalidPortalUrl
        }
        return url
    }

    func getPremiumPlan() async throws -> PremiumPlanResponseModel {
        try await billingAPIService.getPremiumPlan()
    }

    func getSubscription() async throws -> PremiumSubscription {
        let response = try await billingAPIService.getSubscription()
        return PremiumSubscription(response: response)
    }

    func premiumCheckoutCanceled() {
        premiumCheckoutStatusSubject.send(.canceled)
        premiumCheckoutStatusSubject.send(nil)
    }

    func isSelfHosted() async -> Bool {
        guard environmentService.region == .selfHosted || environmentService.region == .internal else {
            return false
        }
        return await !configService.getFeatureFlag(.debugDisableSelfHostPremiumCheck)
    }

    func premiumCheckoutStatusPublisher() -> AnyPublisher<PremiumCheckoutStatus, Never> {
        premiumCheckoutStatusSubject
            .compactMap(\.self)
            .debounce(for: debounceInterval, scheduler: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    func premiumStatusChanged() async {
        guard await refreshAttentionCardAndCheckPremiumUpgradeEligibility() else { return }

        do {
            try await syncService.fetchSync(forceSync: true)
        } catch {
            errorReporter.log(error: error)
        }

        let hasPremium = await stateService.doesActiveAccountHavePremium()
        // Lets a live `PremiumUpgradeHelper`/`PremiumUpgradeProcessor` subscription (from an
        // upgrade attempt still in flight elsewhere) react immediately, rather than only on the
        // vault list's next `.appeared`.
        premiumCheckoutStatusSubject.send(hasPremium ? .confirmed : .pending)
        // Reset unconditionally, unlike `reconcileCheckoutSuccess()`'s deliberately sticky
        // `.pending` for an actual in-flight checkout: this method also runs for a
        // `.premiumStatusChanged` push unrelated to any checkout (an org grant, an expiration),
        // so leaving `.pending` on the `CurrentValueSubject` would replay a bogus pending status
        // to whichever upgrade UI subscribes next, even though no checkout is underway.
        premiumCheckoutStatusSubject.send(nil)
        if hasPremium {
            do {
                try await billingStateService.setUpgradedToPremiumActionCardVisible(true)
            } catch {
                errorReporter.log(error: error)
            }
        }
    }

    func premiumUpgradePendingState() async -> PremiumUpgradePendingState {
        do {
            let isPending = try await billingStateService.getPremiumUpgradePending()
            let lastAttemptFailed = try await billingStateService.getPremiumUpgradeLastSyncAttemptFailed()
            return PremiumUpgradePendingState(isPending: isPending, lastAttemptFailed: lastAttemptFailed)
        } catch {
            errorReporter.log(error: error)
            return PremiumUpgradePendingState(isPending: false, lastAttemptFailed: false)
        }
    }

    func premiumUpgradePendingStatePublisher() -> AnyPublisher<PremiumUpgradePendingState, Never> {
        // `premiumUpgradePendingStateSubject.send(_:)` is called from `refreshPremiumUpgradePendingStateSubject()`,
        // which runs on whichever background `Task` (`start()`'s account/sync subscribers) happens to be
        // resolving it — never guaranteed to be the main thread. Pinned here so a consumer driving
        // `@Published` UI state from this publisher doesn't need to hop to main itself.
        premiumUpgradePendingStateSubject
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    func reconcileCheckoutSuccess() async {
        guard await refreshAttentionCardAndCheckPremiumUpgradePathEligibility() else { return }
        // Snapshot the account this reconcile is for. The "Sync Now" caller
        // (`PremiumUpgradeHelper.pending`) dismisses to an interactive vault list before this
        // method runs, so `fetchSync` below is a real window for the active account to switch.
        let userId = try? await stateService.getActiveAccountId()

        // Unconditional, including for the "Sync Now" tap on `premiumStatusChanged()`'s `.pending`
        // alert (`PremiumUpgradeHelper.swift:147`) — reachable without a real Stripe checkout if an
        // unrelated `.premiumStatusChanged` push lands while the upgrade screen's subscription is
        // live but hasn't confirmed yet. No path clears this for a user who never actually
        // purchased; revisit if that turns out to matter once a later PR consumes this flag.
        do {
            try await billingStateService.setPremiumUpgradePending(true)
        } catch {
            errorReporter.log(error: error)
        }
        await refreshPremiumUpgradePendingStateSubject()

        premiumCheckoutStatusSubject.send(.syncing)
        var syncFailed = false
        // See `checkoutSuccessSync`'s doc comment.
        checkoutSuccessSync = .inFlight(userId: userId)
        do {
            try await syncService.fetchSync(forceSync: true)
        } catch {
            errorReporter.log(error: error)
            syncFailed = true
        }
        checkoutSuccessSync = await .resolved(userId: userId, syncTime: try? stateService.getLastSyncTime())

        // Bail without writing (or publishing) against whichever account is active now if it's
        // no longer the one this reconcile started for, rather than resolving the calls below
        // against an unrelated account's checkout. Clears the `.syncing` sent above first —
        // otherwise it would stay the `CurrentValueSubject`'s value indefinitely and replay to
        // whichever upgrade UI subscribes next, even though no sync is actually in flight for it.
        let accountIdAfterSync = try? await stateService.getActiveAccountId()
        guard accountIdAfterSync == userId else {
            premiumCheckoutStatusSubject.send(nil)
            return
        }

        let hasPremium = await stateService.doesActiveAccountHavePremium()
        do {
            // `syncFailed` and `hasPremium` aren't mutually exclusive: the profile (and its Premium
            // status) is persisted early in `fetchSync()`, so a later step in that same sync can
            // still throw after Premium was already confirmed. Only record a failure if Premium
            // wasn't actually granted, so a confirmed upgrade never persists a contradictory flag.
            try await billingStateService.setPremiumUpgradeLastSyncAttemptFailed(syncFailed && !hasPremium)
        } catch {
            errorReporter.log(error: error)
        }
        // Left set unless Premium is actually confirmed — including when the sync itself failed —
        // so a later sync can still resolve it via `reconcilePendingUpgradeIfNeeded()`. Clearing it
        // on `syncFailed` alone would lose the only record that this checkout ever succeeded with
        // Stripe: the CTA would revert to "Upgrade to Premium" for a user who already paid, and a
        // webhook grant landing later would have nothing pending left to resolve it.
        if hasPremium {
            do {
                try await billingStateService.setPremiumUpgradePending(false)
            } catch {
                errorReporter.log(error: error)
            }
        }
        if hasPremium {
            do {
                try await billingStateService.setUpgradedToPremiumActionCardVisible(true)
            } catch {
                errorReporter.log(error: error)
            }
        }

        premiumCheckoutStatusSubject.send(hasPremium ? .confirmed : .pending)
        if hasPremium {
            premiumCheckoutStatusSubject.send(nil)
        }
        await refreshPremiumUpgradePendingStateSubject()
    }

    func refreshSubscriptionAttentionCard(subscription: PremiumSubscription?) async {
        guard await !isSelfHosted(),
              await configService.getFeatureFlag(.premiumUpgradePath)
        else {
            do {
                try await billingStateService.setSubscriptionAttentionCardVisible(false)
            } catch {
                errorReporter.log(error: error)
            }
            return
        }
        do {
            let sub: PremiumSubscription = if let subscription {
                subscription
            } else {
                try await getSubscription()
            }
            try await billingStateService.setSubscriptionAttentionCardVisible(sub.status.isPaymentProblemState)
        } catch is GetSubscriptionRequestError {
            // No personal subscription — free user or subscription fully gone. Card not shown.
            do {
                try await billingStateService.setSubscriptionAttentionCardVisible(false)
            } catch {
                errorReporter.log(error: error)
            }
        } catch {
            errorReporter.log(error: error)
        }
    }

    func setUpgradedToPremiumActionCardDismissed() async {
        do {
            try await billingStateService.setUpgradedToPremiumActionCardVisible(false)
        } catch {
            errorReporter.log(error: error)
        }
    }

    func shouldShowSubscriptionAttentionCard() async -> Bool {
        do {
            return try await billingStateService.getSubscriptionAttentionCardVisible()
        } catch {
            errorReporter.log(error: error)
            return false
        }
    }

    func shouldShowUpgradedToPremiumActionCard() async -> Bool {
        do {
            return try await billingStateService.getUpgradedToPremiumActionCardVisible()
        } catch {
            errorReporter.log(error: error)
            return false
        }
    }

    func start() async {
        guard !started else { return }
        started = true

        activeAccountSubscriber = Task {
            // `activeAccountIdPublisher()`'s backing store re-emits on every write, not only
            // when the active account actually changes (e.g. once per sync, via
            // `updateProfile(from:userId:)`) — `removeDuplicates()` keeps this subscriber tied
            // to actual account switches.
            for await userId in await self.stateService.activeAccountIdPublisher().removeDuplicates().values {
                self.syncCompletionSubscriber?.cancel()
                guard let userId else {
                    self.premiumUpgradePendingStateSubject.send(
                        PremiumUpgradePendingState(isPending: false, lastAttemptFailed: false),
                    )
                    continue
                }

                await self.refreshPremiumUpgradePendingStateSubject()
                self.syncCompletionSubscriber = Task { await self.reconcileOnEachNewSync(userId: userId) }
            }
        }
    }

    // MARK: Private Methods

    /// Subscribes to the active account's sync completions and reconciles a pending Premium
    /// upgrade after each genuinely new sync.
    ///
    /// - Parameter userId: The user ID of the account this subscriber was started for. Passed
    ///   through to `reconcilePendingUpgradeIfNeeded(userId:lastSyncTime:)` so it can detect an
    ///   account switch that happens after this subscriber has been canceled but while a
    ///   reconcile it started is still finishing.
    ///
    private func reconcileOnEachNewSync(userId: String) async {
        let publisher: AnyPublisher<Date?, Never>
        do {
            publisher = try await stateService.lastSyncTimePublisher()
        } catch {
            errorReporter.log(error: error)
            return
        }

        // Snapshot the last-known sync time directly, rather than relying on whichever value
        // the publisher happens to deliver first: its `CurrentValueSubject` backing replays the
        // existing cached value immediately on subscribe (not evidence that a sync just
        // happened), and a *different* account's sync can also re-emit this shared store
        // without this account's own value having changed. Comparing each emission against the
        // last value actually seen — rather than its position in the stream — means only a
        // genuinely new sync for this account reaches `reconcilePendingUpgradeIfNeeded()`,
        // regardless of subscription timing.
        var lastSeenDate: Date?
        do {
            lastSeenDate = try await stateService.getLastSyncTime()
        } catch {
            errorReporter.log(error: error)
        }

        for await date in publisher.values {
            guard date != lastSeenDate else { continue }
            lastSeenDate = date
            await reconcilePendingUpgradeIfNeeded(userId: userId, lastSyncTime: date)
        }
    }

    /// Checks whether a still-unconfirmed or previously-failed Premium upgrade attempt can now
    /// be resolved, and sets the "Upgraded to Premium" card visible if the active account has
    /// since become Premium (by any means — personal or organization-granted).
    ///
    /// - Parameters:
    ///   - userId: The user ID this reconcile is for. `BillingStateService` has no per-user
    ///     API — every call resolves whichever account is active *at that moment* — so an
    ///     account switch landing mid-suspension could otherwise read one account's flags and
    ///     write another's. Re-checked before each of the writes below, since every `await`
    ///     between them is a genuinely interruptible suspension.
    ///   - lastSyncTime: The last-sync-time value that triggered this reconcile, compared
    ///     against `checkoutSuccessSync` below so a sync `reconcileCheckoutSuccess()` itself
    ///     forced doesn't get raced by this method's independently-scheduled subscriber task.
    ///
    private func reconcilePendingUpgradeIfNeeded(userId: String, lastSyncTime: Date?) async {
        // See `checkoutSuccessSync`'s doc comment: defers to `reconcileCheckoutSuccess()`'s own
        // resolution of `lastAttemptFailed`, whether this runs while that method's forced sync
        // is still in flight (`.inFlight`) or after the fact for that same sync's emission
        // (`.resolved` with a `syncTime` matching this call's `lastSyncTime` exactly).
        switch checkoutSuccessSync {
        case let .inFlight(syncUserId) where syncUserId == userId:
            return
        case let .resolved(syncUserId, syncTime) where syncUserId == userId && syncTime == lastSyncTime:
            return
        default:
            break
        }

        let isPending: Bool
        let lastAttemptFailed: Bool
        do {
            isPending = try await billingStateService.getPremiumUpgradePending()
            lastAttemptFailed = try await billingStateService.getPremiumUpgradeLastSyncAttemptFailed()
        } catch {
            errorReporter.log(error: error)
            return
        }
        guard isPending || lastAttemptFailed else { return }

        // Bail without writing if the active account already switched away from `userId` during
        // the reads above, rather than clearing the newly-active account's failure flag below.
        let accountIdAfterReads = try? await stateService.getActiveAccountId()
        guard accountIdAfterReads == userId else { return }

        // Reached only for syncs `reconcileCheckoutSuccess()` didn't itself force (the guard
        // above defers to that method for its own). `reconcileCheckoutSuccess()` is the only
        // other writer of this flag, so this clear can't race a genuine failure of its
        // checkout-confirmation attempt — but `lastSyncTimePublisher` firing still isn't proof
        // this particular (unrelated) sync succeeded end to end: the last-sync time is
        // persisted before several later steps in `fetchSync()` that can still throw. Clearing
        // unconditionally here treats any forward progress as reason enough to drop a stale
        // failure, on the theory that nothing downstream depends on the persisted value being
        // momentarily wrong — only on the `lastAttemptFailed` snapshotted above, before this
        // write.
        do {
            try await billingStateService.setPremiumUpgradeLastSyncAttemptFailed(false)
        } catch {
            errorReporter.log(error: error)
        }

        let hasPremium = await stateService.doesActiveAccountHavePremium()
        // `start()`'s cancellation of the previous account's subscriber is cooperative — this
        // call can still be running for `userId` after the active account has already switched.
        // Bail without writing if so, rather than resolving the account-scoped calls below (and
        // the rest of `doesActiveAccountHavePremium()` itself, above) against the new account.
        let activeAccountId = try? await stateService.getActiveAccountId()
        guard activeAccountId == userId else { return }

        guard hasPremium else {
            // A checkout that previously failed to confirm just had a sync succeed without
            // finding Premium — promote it back to pending so a later sync can still resolve it,
            // instead of abandoning it now that the failure itself has been cleared above.
            // `!isPending` is reachable even though every production caller sets `isPending`
            // true before ever setting `lastAttemptFailed` true: `reconcileCheckoutSuccess()`'s
            // initial `setPremiumUpgradePending(true)` only logs on failure rather than
            // rethrowing, so that write can silently not persist while a later sync failure
            // still succeeds in persisting `lastAttemptFailed`.
            if lastAttemptFailed, !isPending {
                do {
                    try await billingStateService.setPremiumUpgradePending(true)
                } catch {
                    errorReporter.log(error: error)
                }
            }
            await refreshPremiumUpgradePendingStateSubject()
            return
        }

        do {
            try await billingStateService.setPremiumUpgradePending(false)
            try await billingStateService.setUpgradedToPremiumActionCardVisible(true)
        } catch {
            errorReporter.log(error: error)
        }
        await refreshPremiumUpgradePendingStateSubject()
    }

    /// Refreshes the subscription attention card cache and reports whether the active account
    /// is eligible to participate in the Premium upgrade path at all (self-hosted/feature-flag
    /// gated) — independent of whether Premium has already been granted. Used by
    /// `reconcileCheckoutSuccess()`, where an already-Premium account reached via this method is
    /// the success case, not a no-op.
    ///
    /// - Returns: Whether the active account is eligible for the Premium upgrade path.
    ///
    private func refreshAttentionCardAndCheckPremiumUpgradePathEligibility() async -> Bool {
        await refreshSubscriptionAttentionCard(subscription: nil)
        guard await !isSelfHosted(),
              await configService.getFeatureFlag(.premiumUpgradePath)
        else {
            return false
        }
        return true
    }

    /// As `refreshAttentionCardAndCheckPremiumUpgradePathEligibility()`, but also excludes an
    /// account that already has Premium. Used by `premiumStatusChanged()`, which also runs for
    /// pushes unrelated to any checkout — there, an already-Premium account means there's
    /// nothing left to reconcile.
    ///
    /// - Returns: Whether the active account is eligible for a Premium upgrade sync.
    ///
    private func refreshAttentionCardAndCheckPremiumUpgradeEligibility() async -> Bool {
        guard await refreshAttentionCardAndCheckPremiumUpgradePathEligibility() else { return false }
        return await !stateService.doesActiveAccountHavePremium()
    }

    /// Re-reads the persisted Premium upgrade pending state for the active account and pushes
    /// it into `premiumUpgradePendingStateSubject`.
    ///
    private func refreshPremiumUpgradePendingStateSubject() async {
        await premiumUpgradePendingStateSubject.send(premiumUpgradePendingState())
    }
}
