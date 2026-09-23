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

    /// If the account has a Premium upgrade pending, completes it once the personally purchased
    /// Premium arrives — clearing the pending flag and revealing the "Upgraded to Premium"
    /// action card. Does nothing otherwise, so this can safely run after every sync.
    ///
    /// - Parameters:
    ///   - userId: The account to complete the pending upgrade for.
    ///
    func completePendingUpgrade(userId: String) async

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

    /// A publisher that emits the status of the Premium checkout sync process.
    ///
    func premiumCheckoutStatusPublisher() -> AnyPublisher<PremiumCheckoutStatus, Never>

    /// Notifies that the user completed payment in the Stripe checkout. Confirms whether the
    /// account has been granted Premium yet, syncing to check and publishing checkout status
    /// updates as it resolves. If the sync doesn't confirm Premium (or fails), the upgrade is
    /// left pending so `completePendingUpgrade(userId:)` can finish it once a later sync does.
    ///
    func premiumCheckoutSucceeded() async

    /// Notifies that a Premium status change was detected (via deep link or push notification),
    /// triggers a sync, and publishes status updates.
    ///
    func premiumStatusChanged() async

    /// Gets the active account's current position in the Premium upgrade lifecycle.
    ///
    /// - Returns: The active account's current `PremiumUpgradeLifecycleState`.
    ///
    func premiumUpgradeLifecycleState() async -> PremiumUpgradeLifecycleState

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

    func completePendingUpgrade(userId: String) async {
        await completePendingUpgradeState(userId: userId)
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
        guard let userId = try? await stateService.getActiveAccountId() else { return }

        do {
            try await billingStateService.setPremiumUpgradePending(true, userId: userId)
        } catch {
            errorReporter.log(error: error)
        }

        premiumCheckoutStatusSubject.send(.syncing)
        do {
            try await syncService.fetchSync(forceSync: true)
        } catch {
            errorReporter.log(error: error)
        }

        let upgradeState = await completePendingUpgradeState(userId: userId)

        // Only the account this checkout started for should see its own result.
        guard await (try? stateService.getActiveAccountId()) == userId else { return }
        premiumCheckoutStatusSubject.send(upgradeState == .premium ? .confirmed : .pending)
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
    }

    func premiumUpgradeLifecycleState() async -> PremiumUpgradeLifecycleState {
        await premiumUpgradeLifecycleState(userId: nil)
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

    /// Performs `completePendingUpgrade(userId:)`'s work and additionally reports where the
    /// account ended up, for the caller that needs to act on the outcome.
    ///
    /// - Parameters:
    ///   - userId: The account to complete the pending upgrade for.
    /// - Returns: `userId`'s `PremiumUpgradeLifecycleState` after this completion.
    ///
    @discardableResult
    private func completePendingUpgradeState(userId: String) async -> PremiumUpgradeLifecycleState {
        let wasPending: Bool
        do {
            wasPending = try await billingStateService.getPremiumUpgradePending(userId: userId)
        } catch {
            errorReporter.log(error: error)
            return await premiumUpgradeLifecycleState(userId: userId)
        }
        guard wasPending else { return await premiumUpgradeLifecycleState(userId: userId) }

        // A pending upgrade always comes from a personal checkout, so only personal Premium completes it.
        guard await stateService.doesAccountHavePremiumPersonally(userId: userId) else { return .pending }

        do {
            try await billingStateService.setPremiumUpgradePending(false, userId: userId)
            try await billingStateService.setUpgradedToPremiumActionCardVisible(true, userId: userId)
        } catch {
            errorReporter.log(error: error)
        }
        return .premium
    }

    /// Refreshes the subscription attention card cache and reports whether the active account
    /// is eligible to participate in the Premium upgrade path at all (self-hosted/feature-flag
    /// gated), independent of whether Premium has already been granted.
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

    /// Derives an account's position in the Premium upgrade lifecycle from its Premium status
    /// and its persisted pending flag.
    ///
    /// The three checks are ordered deliberately, and the order is the only thing that
    /// distinguishes the outcomes — both Premium branches return the same `.premium`:
    ///
    /// - Personal Premium is checked first. `completePendingUpgrade(userId:)` clears the pending
    ///   flag in a separate write after Premium is granted, so between the grant and the clear
    ///   — or if that write fails — the flag is stale and must not win.
    /// - The pending flag is checked before organization-granted Premium. The flag is only ever
    ///   set by a personal checkout, so an organization grant arriving while that purchase is
    ///   in flight is not confirmation of it, and must not be reported as the upgrade landing.
    ///
    /// - Parameters:
    ///   - userId: The account to derive the state for. Defaults to the active account if `nil`.
    /// - Returns: The account's current `PremiumUpgradeLifecycleState`.
    ///
    private func premiumUpgradeLifecycleState(userId: String?) async -> PremiumUpgradeLifecycleState {
        if await stateService.doesAccountHavePremiumPersonally(userId: userId) { return .premium }
        do {
            if try await billingStateService.getPremiumUpgradePending(userId: userId) { return .pending }
        } catch {
            errorReporter.log(error: error)
        }
        return await stateService.doesAccountHavePremium(userId: userId) ? .premium : .notPremium
    }
}
