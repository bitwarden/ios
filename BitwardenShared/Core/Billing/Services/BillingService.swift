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
class DefaultBillingService: BillingService {
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
        // A new attempt is starting — clear any stale failure from a prior attempt so it
        // can't incorrectly surface against this one before its own sync has run.
        do {
            try await billingStateService.setPremiumUpgradeLastSyncAttemptFailed(false)
        } catch {
            errorReporter.log(error: error)
        }
        await refreshPremiumUpgradePendingStateSubject()

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
        do {
            try await billingStateService.setPremiumUpgradePending(!hasPremium)
        } catch {
            errorReporter.log(error: error)
        }
        premiumCheckoutStatusSubject.send(hasPremium ? .confirmed : .pending)
        if hasPremium {
            premiumCheckoutStatusSubject.send(nil)
            do {
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
            for await userId in await self.stateService.activeAccountIdPublisher().values {
                self.currentSyncSubscriber?.cancel()
                guard userId != nil else { continue }

                await self.refreshPremiumUpgradePendingStateSubject()

                self.currentSyncSubscriber = Task {
                    guard let publisher = try? await self.stateService.lastSyncTimePublisher() else { return }
                    for await _ in publisher.values {
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

        guard await stateService.doesActiveAccountHavePremium() else { return }

        do {
            try await billingStateService.setPremiumUpgradePending(false)
            try await billingStateService.setPremiumUpgradeLastSyncAttemptFailed(false)
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
