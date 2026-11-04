// swiftlint:disable:this file_name

import BitwardenKitMocks
import Foundation
import TestHelpers
import Testing

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - BillingServiceActionCardTests

/// Tests for the `BillingService` methods that determine action card and banner visibility: the
/// subscription attention card, the "Upgraded to Premium" action card, and the Premium upgrade
/// banner.
///
@MainActor
struct BillingServiceActionCardTests {
    // MARK: Properties

    var billingAPIService: MockBillingAPIService!
    var billingStateService: MockBillingStateService!
    var configService: MockConfigService!
    var environmentService: MockEnvironmentService!
    var errorReporter: MockErrorReporter!
    var subject: DefaultBillingService!

    // MARK: Initialization

    init() {
        billingAPIService = MockBillingAPIService()
        billingAPIService.getSubscriptionReturnValue = .fixture()
        billingStateService = MockBillingStateService()
        billingStateService.getSubscriptionAttentionCardVisibleReturnValue = false
        billingStateService.getUpgradedToPremiumActionCardVisibleReturnValue = false
        billingStateService.getPremiumUpgradeBannerDismissedReturnValue = false
        configService = MockConfigService()
        configService.featureFlagsBool[.premiumUpgradePath] = true
        environmentService = MockEnvironmentService()
        environmentService.region = .unitedStates
        errorReporter = MockErrorReporter()
        subject = DefaultBillingService(
            billingAPIService: billingAPIService,
            billingStateService: billingStateService,
            configService: configService,
            environmentService: environmentService,
            errorReporter: errorReporter,
            stateService: MockStateService(),
            syncService: MockSyncService(),
            debounceInterval: .milliseconds(100),
        )
    }

    // MARK: hasPersonalSubscription

    /// `hasPersonalSubscription()` logs the error and returns `nil` when the state service throws.
    @Test
    func hasPersonalSubscription_error() async {
        billingStateService.getHasPersonalSubscriptionThrowableError = StateServiceError.noActiveAccount

        let result = await subject.hasPersonalSubscription()

        #expect(result == nil)
        #expect(errorReporter.errors as? [StateServiceError] == [.noActiveAccount])
    }

    /// `hasPersonalSubscription()` returns the stored value: `nil` when the server hasn't yet
    /// answered, `false` when it reported no Stripe subscription, and `true` when it reported one.
    @Test(arguments: [nil, false, true] as [Bool?])
    func hasPersonalSubscription_storedValue(storedValue: Bool?) async {
        billingStateService.getHasPersonalSubscriptionReturnValue = storedValue

        let result = await subject.hasPersonalSubscription()

        #expect(result == storedValue)
    }

    // MARK: isPremiumUpgradeBannerDismissed

    /// `isPremiumUpgradeBannerDismissed()` logs the error and returns `false` when the state
    /// service throws.
    @Test
    func isPremiumUpgradeBannerDismissed_error() async {
        billingStateService.getPremiumUpgradeBannerDismissedThrowableError = StateServiceError.noActiveAccount

        let result = await subject.isPremiumUpgradeBannerDismissed()

        #expect(result == false)
        #expect(errorReporter.errors as? [StateServiceError] == [.noActiveAccount])
    }

    /// `isPremiumUpgradeBannerDismissed()` returns `false` when the banner has not been dismissed.
    @Test
    func isPremiumUpgradeBannerDismissed_false() async {
        billingStateService.getPremiumUpgradeBannerDismissedReturnValue = false

        let result = await subject.isPremiumUpgradeBannerDismissed()

        #expect(result == false)
    }

    /// `isPremiumUpgradeBannerDismissed()` returns `true` when the banner has been dismissed.
    @Test
    func isPremiumUpgradeBannerDismissed_true() async {
        billingStateService.getPremiumUpgradeBannerDismissedReturnValue = true

        let result = await subject.isPremiumUpgradeBannerDismissed()

        #expect(result == true)
    }

    // MARK: refreshSubscriptionStatus

    /// `refreshSubscriptionStatus(subscription:)` logs the error and does not update
    /// the cache, or the stored Stripe subscription state, when the API call fails.
    @Test
    func refreshSubscriptionStatus_apiError() async {
        billingAPIService.getSubscriptionThrowableError = URLError(.notConnectedToInternet)

        await subject.refreshSubscriptionStatus(subscription: nil)

        #expect(!billingStateService.setSubscriptionAttentionCardVisibleCalled)
        #expect(!billingStateService.setHasPersonalSubscriptionCalled)
        #expect(errorReporter.errors.first is URLError)
    }

    /// `refreshSubscriptionStatus(subscription:)` sets the cached visibility to `false`
    /// and skips the API call and the stored Stripe subscription update when the feature flag is
    /// disabled.
    @Test
    func refreshSubscriptionStatus_featureFlagDisabled() async {
        configService.featureFlagsBool[.premiumUpgradePath] = false

        await subject.refreshSubscriptionStatus(subscription: nil)

        #expect(billingStateService.setSubscriptionAttentionCardVisibleReceivedVisible == false)
        #expect(!billingAPIService.getSubscriptionCalled)
        #expect(!billingStateService.setHasPersonalSubscriptionCalled)
    }

    /// `refreshSubscriptionStatus(subscription:)` sets the cached visibility to `false`,
    /// stores that the user has no Stripe subscription, and does not log an error when the
    /// server reports no subscription.
    @Test
    func refreshSubscriptionStatus_noSubscription() async {
        billingAPIService.getSubscriptionThrowableError = GetSubscriptionRequestError.noSubscription

        await subject.refreshSubscriptionStatus(subscription: nil)

        #expect(billingStateService.setSubscriptionAttentionCardVisibleReceivedVisible == false)
        #expect(billingStateService.setHasPersonalSubscriptionReceivedArguments?.hasPersonalSubscription == false)
        #expect(errorReporter.errors.isEmpty)
    }

    /// `refreshSubscriptionStatus(subscription:)` stores that the user has a Stripe subscription
    /// when a subscription is provided directly (Plan screen path).
    @Test
    func refreshSubscriptionStatus_providedSubscription_storesHasSubscription() async {
        await subject.refreshSubscriptionStatus(subscription: .fixture())

        #expect(billingStateService.setHasPersonalSubscriptionReceivedArguments?.hasPersonalSubscription == true)
        #expect(!billingAPIService.getSubscriptionCalled)
    }

    /// `refreshSubscriptionStatus(subscription:)` sets the cached visibility to `false`
    /// and skips the API call and the stored Stripe subscription update when the user is
    /// self-hosted.
    @Test
    func refreshSubscriptionStatus_selfHosted() async {
        environmentService.region = .selfHosted

        await subject.refreshSubscriptionStatus(subscription: nil)

        #expect(billingStateService.setSubscriptionAttentionCardVisibleReceivedVisible == false)
        #expect(!billingAPIService.getSubscriptionCalled)
        #expect(!billingStateService.setHasPersonalSubscriptionCalled)
    }

    /// `refreshSubscriptionStatus(subscription:)` sets the cached visibility based on
    /// whether the subscription status requires payment attention.
    @Test(arguments: [
        (SubscriptionStatus.pastDue, true),
        (SubscriptionStatus.unpaid, true),
        (SubscriptionStatus.active, false),
    ])
    func refreshSubscriptionStatus_statusVisibility(
        status: SubscriptionStatus,
        expectedVisible: Bool,
    ) async {
        billingAPIService.getSubscriptionReturnValue = .fixture(status: status)

        await subject.refreshSubscriptionStatus(subscription: nil)

        #expect(billingStateService.setSubscriptionAttentionCardVisibleReceivedVisible == expectedVisible)
    }

    /// `refreshSubscriptionStatus(subscription:)` stores that the user has a Stripe subscription
    /// when the server returns one.
    @Test
    func refreshSubscriptionStatus_subscriptionFetched_storesHasSubscription() async {
        await subject.refreshSubscriptionStatus(subscription: nil)

        #expect(billingStateService.setHasPersonalSubscriptionReceivedArguments?.hasPersonalSubscription == true)
    }

    /// `refreshSubscriptionStatus(subscription:)` sets the cached visibility to `true`
    /// when a subscription with `.unpaid` status is provided directly (Plan screen path).
    @Test
    func refreshSubscriptionStatus_unpaid_providedSubscription() async {
        await subject.refreshSubscriptionStatus(subscription: .fixture(status: .unpaid))

        #expect(billingStateService.setSubscriptionAttentionCardVisibleReceivedVisible == true)
        #expect(!billingAPIService.getSubscriptionCalled)
    }

    /// `refreshSubscriptionStatus(subscription:)` uses an already-fetched subscription
    /// instead of making a new API call when one is provided.
    @Test
    func refreshSubscriptionStatus_usesProvidedSubscription() async {
        await subject.refreshSubscriptionStatus(subscription: .fixture(status: .pastDue))

        #expect(billingStateService.setSubscriptionAttentionCardVisibleReceivedVisible == true)
        #expect(!billingAPIService.getSubscriptionCalled)
    }

    // MARK: setPremiumUpgradeBannerDismissed

    /// `setPremiumUpgradeBannerDismissed()` dismisses the banner for the active account.
    @Test
    func setPremiumUpgradeBannerDismissed() async throws {
        try await subject.setPremiumUpgradeBannerDismissed()

        #expect(billingStateService.setPremiumUpgradeBannerDismissedReceivedArguments?.dismissed == true)
        #expect(billingStateService.setPremiumUpgradeBannerDismissedReceivedArguments?.userId == nil)
    }

    /// `setPremiumUpgradeBannerDismissed()` rethrows errors from the state service.
    @Test
    func setPremiumUpgradeBannerDismissed_error() async {
        billingStateService.setPremiumUpgradeBannerDismissedThrowableError = StateServiceError.noActiveAccount

        await #expect(throws: StateServiceError.noActiveAccount) {
            try await subject.setPremiumUpgradeBannerDismissed()
        }
    }

    // MARK: setUpgradedToPremiumActionCardDismissed

    /// `setUpgradedToPremiumActionCardDismissed()` sets the visibility flag to `false` for the active account.
    @Test
    func setUpgradedToPremiumActionCardDismissed() async {
        billingStateService.getUpgradedToPremiumActionCardVisibleReturnValue = true

        await subject.setUpgradedToPremiumActionCardDismissed()

        #expect(billingStateService.setUpgradedToPremiumActionCardVisibleReceivedArguments?.visible == false)
    }

    /// `setUpgradedToPremiumActionCardDismissed()` logs an error if the state service throws.
    @Test
    func setUpgradedToPremiumActionCardDismissed_error() async {
        billingStateService.setUpgradedToPremiumActionCardVisibleThrowableError = StateServiceError.noActiveAccount

        await subject.setUpgradedToPremiumActionCardDismissed()

        #expect(errorReporter.errors.first as? StateServiceError == .noActiveAccount)
    }

    // MARK: shouldShowSubscriptionAttentionCard

    /// `shouldShowSubscriptionAttentionCard()` returns the cached value without making an API call.
    @Test
    func shouldShowSubscriptionAttentionCard_returnsFromCache() async {
        billingStateService.getSubscriptionAttentionCardVisibleReturnValue = true

        let result = await subject.shouldShowSubscriptionAttentionCard()

        #expect(result)
        #expect(!billingAPIService.getSubscriptionCalled)
    }

    // MARK: shouldShowUpgradedToPremiumActionCard

    /// `shouldShowUpgradedToPremiumActionCard()` returns `false` when the state service reports it is not visible.
    @Test
    func shouldShowUpgradedToPremiumActionCard_notVisible() async {
        billingStateService.getUpgradedToPremiumActionCardVisibleReturnValue = false

        let result = await subject.shouldShowUpgradedToPremiumActionCard()

        #expect(result == false)
    }

    /// `shouldShowUpgradedToPremiumActionCard()` returns `true` when the state service reports the card is visible.
    @Test
    func shouldShowUpgradedToPremiumActionCard_visible() async {
        billingStateService.getUpgradedToPremiumActionCardVisibleReturnValue = true

        let result = await subject.shouldShowUpgradedToPremiumActionCard()

        #expect(result == true)
    }
}
