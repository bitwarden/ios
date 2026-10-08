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

    /// Clears the account's pending Premium upgrade and reveals the "Upgraded to Premium" action
    /// card once the personally purchased Premium has arrived. Does nothing for an account with no
    /// pending upgrade, so this can safely run after every sync.
    ///
    /// This is the only place a pending upgrade completes.
    ///
    /// - Parameters:
    ///   - userId: The account to complete the pending upgrade for.
    ///
    func completeUpgradeIfPending(userId: String) async

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

    /// Gets whether the Premium upgrade banner has been dismissed by the active account.
    ///
    /// - Returns: Whether the banner has been dismissed.
    ///
    func isPremiumUpgradeBannerDismissed() async -> Bool

    /// Returns whether the current environment is effectively self-hosted for Premium upgrade checks.
    /// Returns `false` when the debug override flag is enabled, regardless of the actual region.
    ///
    func isSelfHosted() async -> Bool

    /// Notifies that the user canceled the Stripe checkout without completing payment,
    /// and publishes a `.canceled` status update.
    ///
    func premiumCheckoutCanceled()

    /// A publisher that emits the status of the Premium checkout sync process. Subscribers receive
    /// only statuses published after they subscribe; a previously published status is never
    /// replayed.
    ///
    func premiumCheckoutStatusPublisher() -> AnyPublisher<PremiumCheckoutStatus, Never>

    /// Notifies that the user completed payment in the Stripe checkout, marking the active
    /// account's upgrade pending, then force-syncing and publishing `.confirmed` or `.pending`.
    /// Does nothing if the account isn't eligible for the Premium upgrade path. The upgrade stays
    /// pending until a sync reports the purchased Premium.
    ///
    /// Marking the upgrade pending asserts that a purchase was made, so only call this after
    /// observing a successful Stripe callback. Use `retryPendingUpgrade()` for a user-initiated
    /// retry, which makes no such assertion.
    ///
    func premiumCheckoutSucceeded() async

    /// Notifies that a `premiumStatusChanged` push notification arrived, and force-syncs the
    /// active account. The sync's own completion handling reconciles a pending upgrade and
    /// refreshes the subscription attention card; this publishes no checkout status.
    ///
    /// This always syncs, whichever account the push names and whether or not the account already
    /// has Premium or is eligible for the Premium upgrade path. The server sends this push for
    /// changes that don't bump the account's revision date (e.g. a payment on a past-due
    /// subscription, or a self-hosted license change), so a non-forced sync would skip them.
    ///
    func premiumStatusChanged() async

    /// Derives an account's position in the Premium upgrade lifecycle from its Premium status
    /// and its persisted pending flag.
    ///
    /// If the account can't be resolved, the error is logged and `.notPremium` is returned. If the
    /// pending flag can't be read, the error is logged and the account is treated as not pending.
    ///
    /// - Parameters:
    ///   - userId: The account to derive the state for. Defaults to the active account if `nil`.
    /// - Returns: The account's current `PremiumUpgradeLifecycleState`.
    ///
    func premiumUpgradeLifecycleState(userId: String?) async -> PremiumUpgradeLifecycleState

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

    /// Retries an upgrade that is already pending. Like `premiumCheckoutSucceeded()`, but never
    /// marks an upgrade pending, so it's safe for a user-initiated retry that may not follow a
    /// real checkout.
    ///
    func retryPendingUpgrade() async

    /// Sets the Premium upgrade banner as dismissed for the active account, so it is not shown again.
    ///
    func setPremiumUpgradeBannerDismissed() async throws

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
}

// MARK: - BillingService Convenience Methods

extension BillingService {
    /// Derives the active account's position in the Premium upgrade lifecycle.
    ///
    /// - Returns: The active account's current `PremiumUpgradeLifecycleState`.
    ///
    func premiumUpgradeLifecycleState() async -> PremiumUpgradeLifecycleState {
        await premiumUpgradeLifecycleState(userId: nil)
    }
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

    /// The debounce interval applied to the Premium checkout status publisher.
    private let debounceInterval: DispatchQueue.SchedulerTimeType.Stride

    /// The service used to manage the app's environment URLs.
    private let environmentService: EnvironmentService

    /// The service used by the application to report non-fatal errors.
    private let errorReporter: ErrorReporter

    /// Subject that emits the Premium checkout sync status. Subscribers attach fresh per upgrade
    /// flow, so this must never replay a status from a previous flow or account.
    private let premiumCheckoutStatusSubject = PassthroughSubject<PremiumCheckoutStatus, Never>()

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

    func completeUpgradeIfPending(userId: String) async {
        do {
            // A pending upgrade always comes from a personal checkout, so only personal Premium
            // completes it — an organization grant arriving mid-flight isn't the purchase landing.
            guard try await billingStateService.getPremiumUpgradePending(userId: userId),
                  await stateService.doesAccountHavePremiumPersonally(userId: userId)
            else {
                return
            }
            try await billingStateService.setPremiumUpgradePending(false, userId: userId)
            try await billingStateService.setUpgradedToPremiumActionCardVisible(true, userId: userId)
        } catch {
            errorReporter.log(error: error)
        }
    }

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

    func isPremiumUpgradeBannerDismissed() async -> Bool {
        do {
            return try await billingStateService.getPremiumUpgradeBannerDismissed()
        } catch {
            errorReporter.log(error: error)
            return false
        }
    }

    func isSelfHosted() async -> Bool {
        guard environmentService.region == .selfHosted || environmentService.region == .internal else {
            return false
        }
        return await !configService.getFeatureFlag(.debugDisableSelfHostPremiumCheck)
    }

    func premiumCheckoutCanceled() {
        premiumCheckoutStatusSubject.send(.canceled)
    }

    func premiumCheckoutStatusPublisher() -> AnyPublisher<PremiumCheckoutStatus, Never> {
        premiumCheckoutStatusSubject
            .debounce(for: debounceInterval, scheduler: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    func premiumCheckoutSucceeded() async {
        guard await isEligibleForPremiumUpgradePath() else { return }

        let userId: String
        do {
            userId = try await stateService.getActiveAccountId()
        } catch {
            errorReporter.log(error: error)
            premiumCheckoutStatusSubject.send(.pending)
            return
        }

        do {
            try await billingStateService.setPremiumUpgradePending(true, userId: userId)
        } catch {
            errorReporter.log(error: error)
        }

        await syncAndReport(userId: userId)
    }

    func premiumStatusChanged() async {
        do {
            try await syncService.fetchSync(forceSync: true)
        } catch {
            errorReporter.log(error: error)
        }
    }

    func premiumUpgradeLifecycleState(userId: String?) async -> PremiumUpgradeLifecycleState {
        // Resolved once so all three reads see the same account, even if the active account
        // changes partway through.
        let resolvedUserId: String
        do {
            resolvedUserId = try await stateService.getAccountIdOrActiveId(userId: userId)
        } catch {
            errorReporter.log(error: error)
            return .notPremium
        }

        // Personal Premium wins over the pending flag. `completeUpgradeIfPending(userId:)` clears
        // the flag in a separate write after a sync reports Premium, so between the two — or if
        // that write fails — the flag is stale.
        if await stateService.doesAccountHavePremiumPersonally(userId: resolvedUserId) { return .premium }

        // The pending flag wins over organization-granted Premium. Only a personal checkout sets
        // the flag, so an organization grant arriving while that purchase is in flight isn't the
        // purchase landing.
        do {
            if try await billingStateService.getPremiumUpgradePending(userId: resolvedUserId) { return .pending }
        } catch {
            errorReporter.log(error: error)
        }

        // Personal Premium was ruled out above, so any Premium here is organization-granted.
        return await stateService.doesAccountHavePremium(userId: resolvedUserId) ? .premium : .notPremium
    }

    func refreshSubscriptionAttentionCard(subscription: PremiumSubscription?) async {
        guard await isEligibleForPremiumUpgradePath() else {
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

    func retryPendingUpgrade() async {
        guard await isEligibleForPremiumUpgradePath() else { return }

        let userId: String
        do {
            userId = try await stateService.getActiveAccountId()
        } catch {
            errorReporter.log(error: error)
            premiumCheckoutStatusSubject.send(.pending)
            return
        }

        await syncAndReport(userId: userId)
    }

    func setPremiumUpgradeBannerDismissed() async throws {
        try await billingStateService.setPremiumUpgradeBannerDismissed(true)
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

    // MARK: Private Methods

    /// Reports whether the Premium upgrade path is available: not self-hosted, and the
    /// `premiumUpgradePath` feature flag is enabled.
    ///
    /// - Returns: Whether the Premium upgrade path is available.
    ///
    private func isEligibleForPremiumUpgradePath() async -> Bool {
        guard await !isSelfHosted(),
              await configService.getFeatureFlag(.premiumUpgradePath)
        else {
            return false
        }
        return true
    }

    /// Publishes `.syncing`, force-syncs, and publishes whether the sync landed `userId`'s
    /// purchased Premium: `.confirmed` if the sync succeeded and the account has personal
    /// Premium, and `.pending` if the sync threw or the account has no personal Premium.
    ///
    /// The outcome is decided from the sync result and personal Premium alone, not the pending
    /// flag, so a failed pending write can't leave the waiting overlay without a result, and
    /// organization-granted Premium can't pass for the purchase landing.
    ///
    /// - Parameters:
    ///   - userId: The account whose purchased Premium to check for after the sync.
    ///
    private func syncAndReport(userId: String) async {
        premiumCheckoutStatusSubject.send(.syncing)
        do {
            try await syncService.fetchSync(forceSync: true)
        } catch {
            errorReporter.log(error: error)
            premiumCheckoutStatusSubject.send(.pending)
            return
        }
        let hasPremium = await stateService.doesAccountHavePremiumPersonally(userId: userId)
        premiumCheckoutStatusSubject.send(hasPremium ? .confirmed : .pending)
    }
}
