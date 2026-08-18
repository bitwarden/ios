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

    /// Creates a checkout session for Premium upgrade, marks the upgrade as pending, and
    /// returns the checkout URL.
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
    /// clears the pending state `createCheckoutSession()` set for this attempt, and publishes
    /// a `.canceled` status update.
    ///
    func premiumCheckoutCanceled() async

    /// A publisher that emits the status of the Premium checkout sync process.
    ///
    func premiumCheckoutStatusPublisher() -> AnyPublisher<PremiumCheckoutStatus, Never>

    /// Returns whether the current environment is effectively self-hosted for Premium upgrade checks.
    /// Returns `false` when the debug override flag is enabled, regardless of the actual region.
    ///
    func isSelfHosted() async -> Bool

    /// Notifies that a Premium status change was detected (via deep link or push notification)
    /// and triggers a sync. If an upgrade is pending, publishes checkout status updates as the
    /// sync resolves it; otherwise performs a plain sync to pick up the change.
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
    // MARK: Properties

    /// The API service used for billing requests.
    private let billingAPIService: BillingAPIService

    /// The service used to manage the app's billing state.
    private let billingStateService: BillingStateService

    let checkoutCallbackUrlScheme = "bitwarden"

    /// The service used to manage feature flags.
    private let configService: ConfigService

    /// The task that watches for sync completions for the currently active account, to
    /// reconcile a pending Premium upgrade if one exists.
    private var currentSyncSubscriber: Task<Void, Never>?

    /// The debounce interval applied to the Premium checkout status publisher.
    private let debounceInterval: DispatchQueue.SchedulerTimeType.Stride

    /// The service used to manage the app's environment URLs.
    private let environmentService: EnvironmentService

    /// The service used by the application to report non-fatal errors.
    private let errorReporter: ErrorReporter

    /// The task that watches for active-account changes and re-subscribes
    /// `currentSyncSubscriber` accordingly.
    private var lastSyncSubscriber: Task<Void, Never>?

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
        // Clear any stale failure from a prior attempt so it can't incorrectly surface against
        // this one before its own sync has run.
        do {
            try await billingStateService.setPremiumUpgradeLastSyncAttemptFailed(false)
        } catch {
            errorReporter.log(error: error)
        }

        let response = try await billingAPIService.createCheckoutSession()
        let url = response.checkoutSessionUrl
        // Ensure the checkout URL uses HTTPS to prevent man-in-the-middle attacks
        // when redirecting users to the payment provider.
        guard url.scheme == "https" else {
            throw BillingError.invalidCheckoutUrl
        }

        // Only now do we know an attempt is actually about to begin — mark it pending. This is
        // the only place `premiumUpgradePending` is ever set to `true`: `premiumStatusChanged()`
        // only reconciles an attempt already marked pending here, so a `.premiumStatusChanged`
        // push for an account that never started a checkout has nothing to act on. Marking it
        // any earlier (e.g. before the API call) would leave a stuck pending state behind if
        // this method throws, with nothing left to ever clear it.
        do {
            try await billingStateService.setPremiumUpgradePending(true)
        } catch {
            errorReporter.log(error: error)
        }
        await refreshPremiumUpgradePendingStateSubject()

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

    func premiumCheckoutCanceled() async {
        // Undo the pending mark `createCheckoutSession()` made for this attempt — no attempt is
        // actually in flight anymore, so nothing should stay hidden/pending on its account.
        do {
            try await billingStateService.setPremiumUpgradePending(false)
        } catch {
            errorReporter.log(error: error)
        }
        await refreshPremiumUpgradePendingStateSubject()
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
        // Refresh the attention card cache regardless of premium status — past-due and
        // update-payment users still have premium, so they would be excluded by the guard below.
        await refreshSubscriptionAttentionCard(subscription: nil)

        guard await !isSelfHosted(),
              await configService.getFeatureFlag(.premiumUpgradePath),
              await !stateService.doesActiveAccountHavePremium()
        else {
            return
        }

        // The checkout-status publisher and the persisted pending/failure state only make sense
        // in the context of an in-app upgrade attempt already in flight — the Stripe checkout
        // callback confirming, or an explicit "Sync Now"/"Try Again" retry. `createCheckoutSession()`
        // is the only place that marks an attempt pending. But this method is also the target of
        // a generic `.premiumStatusChanged` push for an account that never started one — Premium
        // granted via the web vault, another device, or an org — which still needs a sync to
        // pick up the change locally, just without touching checkout-specific state.
        let isPending: Bool
        do {
            isPending = try await billingStateService.getPremiumUpgradePending()
        } catch {
            errorReporter.log(error: error)
            isPending = false
        }
        guard isPending else {
            do {
                try await syncService.fetchSync(forceSync: false)
            } catch {
                errorReporter.log(error: error)
            }
            return
        }

        premiumCheckoutStatusSubject.send(.syncing)
        var syncFailed = false
        do {
            try await syncService.fetchSync(forceSync: true)
        } catch {
            errorReporter.log(error: error)
            syncFailed = true
        }
        do {
            try await billingStateService.setPremiumUpgradeLastSyncAttemptFailed(syncFailed)
        } catch {
            errorReporter.log(error: error)
        }

        let hasPremium = await stateService.doesActiveAccountHavePremium()
        premiumCheckoutStatusSubject.send(hasPremium ? .confirmed : .pending)
        if hasPremium {
            premiumCheckoutStatusSubject.send(nil)
            do {
                try await billingStateService.setPremiumUpgradePending(false)
                try await billingStateService.setUpgradedToPremiumActionCardVisible(true)
            } catch {
                errorReporter.log(error: error)
            }
        }
        await refreshPremiumUpgradePendingStateSubject()
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
        premiumUpgradePendingStateSubject.eraseToAnyPublisher()
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

        lastSyncSubscriber = Task {
            // `activeAccountIdPublisher()`'s backing store re-emits on every write, not only
            // when the active account actually changes (e.g. once per sync, via
            // `updateProfile(from:userId:)`) — `removeDuplicates()` keeps this subscriber tied
            // to actual account switches, matching what its own doc comment describes.
            for await userId in await self.stateService.activeAccountIdPublisher().removeDuplicates().values {
                self.currentSyncSubscriber?.cancel()
                guard userId != nil else { continue }

                await self.refreshPremiumUpgradePendingStateSubject()

                self.currentSyncSubscriber = Task {
                    guard let publisher = try? await self.stateService.lastSyncTimePublisher() else { return }
                    // Snapshot the last-known sync time directly, rather than relying on
                    // whichever value the publisher happens to deliver first: its
                    // `CurrentValueSubject` backing replays the existing cached value
                    // immediately on subscribe (not evidence that a sync just happened), and a
                    // *different* account's sync can also re-emit this shared store without this
                    // account's own value having changed. Comparing each emission against the
                    // last value actually seen — rather than its position in the stream — means
                    // only a genuinely new sync for this account reaches
                    // `reconcilePendingUpgradeIfNeeded()`, regardless of subscription timing.
                    var lastSeenDate = try? await self.stateService.getLastSyncTime()
                    for await date in publisher.values {
                        guard date != lastSeenDate else { continue }
                        lastSeenDate = date
                        await self.reconcilePendingUpgradeIfNeeded()
                    }
                }
            }
        }
    }

    // MARK: Private Methods

    /// Checks whether a pending Premium upgrade can now be resolved, and clears the pending
    /// state if the active account has since become Premium (by any means — personal or
    /// organization-granted).
    ///
    private func reconcilePendingUpgradeIfNeeded() async {
        do {
            guard try await billingStateService.getPremiumUpgradePending() else { return }
        } catch {
            errorReporter.log(error: error)
            return
        }

        // Reaching this point at all means a *new* sync just completed successfully — `start()`
        // filters out both the initial replay and same-value re-emissions before invoking this
        // method, and `lastSyncTimePublisher` never fires on failure — so the most recent
        // attempt did not fail. Clear that regardless of whether the account has become Premium
        // yet, so a stale failure doesn't linger after a later, unrelated sync has succeeded.
        do {
            try await billingStateService.setPremiumUpgradeLastSyncAttemptFailed(false)
        } catch {
            errorReporter.log(error: error)
        }

        guard await stateService.doesActiveAccountHavePremium() else {
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

    /// Re-reads the persisted Premium upgrade pending state for the active account and pushes
    /// it into `premiumUpgradePendingStateSubject`.
    ///
    private func refreshPremiumUpgradePendingStateSubject() async {
        await premiumUpgradePendingStateSubject.send(premiumUpgradePendingState())
    }
}
