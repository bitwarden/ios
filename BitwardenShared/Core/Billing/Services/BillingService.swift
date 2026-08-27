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

    /// Notifies that the user canceled the Stripe checkout without completing payment,
    /// and publishes a `.canceled` status update.
    ///
    func premiumCheckoutCanceled()

    /// A publisher that emits the status of the Premium checkout sync process.
    ///
    func premiumCheckoutStatusPublisher() -> AnyPublisher<PremiumCheckoutStatus, Never>

    /// Returns whether the current environment is effectively self-hosted for Premium upgrade checks.
    /// Returns `false` when the debug override flag is enabled, regardless of the actual region.
    ///
    func isSelfHosted() async -> Bool

    /// Notifies that a Premium status change was detected (via deep link or push notification),
    /// triggers a sync, and publishes status updates.
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
    /// to check and publishing checkout status updates as it resolves. If the sync doesn't
    /// confirm Premium (or fails), the upgrade is left pending so `start()`'s background watcher
    /// can resolve it once a later sync does.
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
    /// successful sync for the active account — not just the sync `reconcileCheckoutSuccess()`
    /// itself forces. Should be called once, for the lifetime of the app.
    ///
    func start() async
}

// MARK: - DefaultBillingService

/// The default implementation of `BillingService`.
///
class DefaultBillingService: BillingService { // swiftlint:disable:this type_body_length
    // MARK: Properties

    /// The task that watches for active-account changes and re-subscribes
    /// `syncCompletionSubscriber` accordingly.
    private var activeAccountSubscriber: Task<Void, Never>?

    /// The API service used for billing requests.
    private let billingAPIService: BillingAPIService

    /// The service used to manage the app's billing state.
    private let billingStateService: BillingStateService

    let checkoutCallbackUrlScheme = "bitwarden"

    /// The service used to manage feature flags.
    private let configService: ConfigService

    /// The debounce interval applied to the Premium checkout status publisher.
    private let debounceInterval: DispatchQueue.SchedulerTimeType.Stride

    /// The service used to manage the app's environment URLs.
    private let environmentService: EnvironmentService

    /// The service used by the application to report non-fatal errors.
    private let errorReporter: ErrorReporter

    /// Subject that emits the Premium checkout sync status. A `PassthroughSubject`, deliberately
    /// not a `CurrentValueSubject`: subscribers attach fresh at the start of each upgrade flow,
    /// before any status for that flow can exist, and must never replay a stale status left over
    /// from a previous flow or account to a new subscriber.
    private let premiumCheckoutStatusSubject = PassthroughSubject<PremiumCheckoutStatus, Never>()

    /// Subject that emits the Premium upgrade pending state for the active account.
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
    }

    func isSelfHosted() async -> Bool {
        guard environmentService.region == .selfHosted || environmentService.region == .internal else {
            return false
        }
        return await !configService.getFeatureFlag(.debugDisableSelfHostPremiumCheck)
    }

    func premiumCheckoutStatusPublisher() -> AnyPublisher<PremiumCheckoutStatus, Never> {
        premiumCheckoutStatusSubject
            .debounce(for: debounceInterval, scheduler: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    func premiumStatusChanged() async {
        // Refresh the attention card cache regardless of premium status — past-due and
        // update-payment users still have premium, so they would be excluded by the guard below.
        await refreshSubscriptionAttentionCard(subscription: nil)

        guard await !isSelfHosted(),
              await configService.getFeatureFlag(.premiumUpgradePath),
              await !stateService.doesActiveAccountHavePremium()
        else {
            return
        }

        premiumCheckoutStatusSubject.send(.syncing)
        do {
            try await syncService.fetchSync(forceSync: true)
        } catch {
            errorReporter.log(error: error)
        }
        let hasPremium = await stateService.doesActiveAccountHavePremium()
        premiumCheckoutStatusSubject.send(hasPremium ? .confirmed : .pending)
        if hasPremium {
            do {
                try await billingStateService.setUpgradedToPremiumActionCardVisible(true)
            } catch {
                errorReporter.log(error: error)
            }
        }
        // No further action needed if a pending upgrade was also in flight: the forced sync
        // above updates the active account's last-sync time either way, and `start()`'s
        // background watcher resolves any pending upgrade generically on every sync.
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
        // `premiumUpgradePendingStateSubject.send(_:)` is called from whichever background
        // `Task` (`start()`'s account/sync subscribers) happens to be resolving it — never
        // guaranteed to be the main thread. Pinned here so a consumer driving `@Published` UI
        // state from this publisher doesn't need to hop to main itself.
        premiumUpgradePendingStateSubject
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    func reconcileCheckoutSuccess() async {
        guard await isEligibleForPremiumUpgradePath() else { return }
        guard let userId = try? await stateService.getActiveAccountId() else { return }

        do {
            try await billingStateService.setPremiumUpgradePending(true, userId: userId)
        } catch {
            errorReporter.log(error: error)
        }
        await refreshPremiumUpgradePendingStateSubject()

        premiumCheckoutStatusSubject.send(.syncing)
        var syncFailed = false
        do {
            try await syncService.fetchSync(forceSync: true)
        } catch {
            errorReporter.log(error: error)
            syncFailed = true
        }

        let hasPremium = await resolvePendingUpgrade(userId: userId, syncFailed: syncFailed)
        await refreshPremiumUpgradePendingStateSubject()

        // Only the account this reconcile started for should see its own checkout result — the
        // "Sync Now" tap that led here already dismissed to an interactive vault list, so the
        // active account can have switched away while the sync above was in flight.
        guard await (try? stateService.getActiveAccountId()) == userId else { return }
        premiumCheckoutStatusSubject.send(hasPremium ? .confirmed : .pending)
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

    /// Refreshes the subscription attention card cache and reports whether the active account
    /// is eligible to participate in the Premium upgrade path at all (self-hosted/feature-flag
    /// gated) — independent of whether Premium has already been granted. Used by
    /// `reconcileCheckoutSuccess()`, where an already-Premium account reached via this method is
    /// the success case, not a no-op.
    ///
    /// - Returns: Whether the active account is eligible for the Premium upgrade path.
    ///
    private func isEligibleForPremiumUpgradePath() async -> Bool {
        await refreshSubscriptionAttentionCard(subscription: nil)
        guard await !isSelfHosted(),
              await configService.getFeatureFlag(.premiumUpgradePath)
        else {
            return false
        }
        return true
    }

    /// Subscribes to the active account's sync completions and resolves a pending Premium
    /// upgrade after each genuinely new sync.
    ///
    /// - Parameter userId: The user ID of the account this subscriber was started for.
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
        // without this account's own value having changed.
        var lastSeenDate: Date?
        do {
            lastSeenDate = try await stateService.getLastSyncTime()
        } catch {
            errorReporter.log(error: error)
        }

        for await date in publisher.values {
            guard date != lastSeenDate else { continue }
            lastSeenDate = date
            _ = await resolvePendingUpgrade(userId: userId, syncFailed: false)
            await refreshPremiumUpgradePendingStateSubject()
        }
    }

    /// Refreshes the persisted Premium upgrade pending state for the active account and pushes
    /// it into `premiumUpgradePendingStateSubject`.
    ///
    private func refreshPremiumUpgradePendingStateSubject() async {
        await premiumUpgradePendingStateSubject.send(premiumUpgradePendingState())
    }

    /// Resolves a pending Premium upgrade for `userId`, if one is recorded: checks whether the
    /// account now has Premium, persists the result, and — once confirmed — shows the
    /// "Upgraded to Premium" card. Leaves persisted state untouched if `userId` has no pending
    /// upgrade or prior failure recorded, so this can safely run on every sync for every account,
    /// not just those mid-upgrade — it still always reports current Premium status, though.
    ///
    /// Called both right after a checkout's own forced sync (`reconcileCheckoutSuccess()`) and
    /// from the background watcher on every subsequent sync (`reconcileOnEachNewSync(userId:)`).
    /// Every read and write here is scoped to the explicit `userId` passed in, not whichever
    /// account happens to be active when this runs, so an account switch mid-flight can't
    /// corrupt a different account's flags, and calling this twice for the same sync is
    /// redundant but never incorrect for the flags it fully owns (`isPending`, the "Upgraded to
    /// Premium" card).
    ///
    /// One case is a deliberately accepted exception: if `reconcileCheckoutSuccess()`'s own
    /// forced sync updates the last-sync time (so the background watcher also reacts to it) but
    /// then throws on a later step, whichever of the two calls persists `lastAttemptFailed` last
    /// wins — the watcher's `syncFailed: false` can overwrite this call's `true`. Left unresolved
    /// since the only planned consumer of `lastAttemptFailed`, the "Sync Unsuccessful" dialog, is
    /// itself still undecided (see PM-39767); `isPending` — which every path here agrees on — is
    /// what keeps the upgrade from being abandoned in the meantime.
    ///
    /// - Parameters:
    ///   - userId: The account to resolve the pending upgrade for.
    ///   - syncFailed: Whether the sync that triggered this resolution failed outright.
    /// - Returns: Whether `userId` has Premium after this resolution.
    ///
    @discardableResult
    private func resolvePendingUpgrade(userId: String, syncFailed: Bool) async -> Bool {
        let isPending: Bool
        let lastAttemptFailed: Bool
        do {
            isPending = try await billingStateService.getPremiumUpgradePending(userId: userId)
            lastAttemptFailed = try await billingStateService.getPremiumUpgradeLastSyncAttemptFailed(userId: userId)
        } catch {
            errorReporter.log(error: error)
            return await stateService.doesAccountHavePremium(userId: userId)
        }
        // Regardless of which branch below runs, the return value always answers "does `userId`
        // have Premium right now" — never a stand-in like "was anything pending." The background
        // sync watcher (`reconcileOnEachNewSync(userId:)`) and this method's other caller
        // (`reconcileCheckoutSuccess()`) can both resolve the same sync, and whichever runs
        // second must still get an accurate answer even though there's nothing left pending by
        // the time it checks.
        guard isPending || lastAttemptFailed else {
            return await stateService.doesAccountHavePremium(userId: userId)
        }

        let hasPremium = await stateService.doesAccountHavePremium(userId: userId)
        do {
            // `syncFailed` and `hasPremium` aren't mutually exclusive: the profile (and its
            // Premium status) is persisted early in `fetchSync()`, so a later step in that same
            // sync can still throw after Premium was already confirmed. Only record a failure if
            // Premium wasn't actually granted, so a confirmed upgrade never persists a
            // contradictory flag.
            try await billingStateService.setPremiumUpgradeLastSyncAttemptFailed(
                syncFailed && !hasPremium,
                userId: userId,
            )
            try await billingStateService.setPremiumUpgradePending(!hasPremium, userId: userId)
            if hasPremium {
                try await billingStateService.setUpgradedToPremiumActionCardVisible(true, userId: userId)
            }
        } catch {
            errorReporter.log(error: error)
        }
        return hasPremium
    }
}
