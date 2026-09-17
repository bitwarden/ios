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
        billingStateService.isPremiumUpgradeBannerDismissedReturnValue = false
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

    // MARK: isPremiumUpgradeBannerDismissed

    /// `isPremiumUpgradeBannerDismissed()` returns `false` when the banner has not been dismissed.
    @Test
    func isPremiumUpgradeBannerDismissed_false() async {
        billingStateService.isPremiumUpgradeBannerDismissedReturnValue = false

        let result = await subject.isPremiumUpgradeBannerDismissed()

        #expect(result == false)
    }

    /// `isPremiumUpgradeBannerDismissed()` returns `true` when the banner has been dismissed.
    @Test
    func isPremiumUpgradeBannerDismissed_true() async {
        billingStateService.isPremiumUpgradeBannerDismissedReturnValue = true

        let result = await subject.isPremiumUpgradeBannerDismissed()

        #expect(result == true)
    }

    // MARK: refreshSubscriptionAttentionCard

    /// `refreshSubscriptionAttentionCard(subscription:)` logs the error and does not update
    /// the cache when the API call fails.
    @Test
    func refreshSubscriptionAttentionCard_apiError() async {
        billingAPIService.getSubscriptionThrowableError = URLError(.notConnectedToInternet)

        await subject.refreshSubscriptionAttentionCard(subscription: nil)

        #expect(!billingStateService.setSubscriptionAttentionCardVisibleCalled)
        #expect(errorReporter.errors.first is URLError)
    }

    /// `refreshSubscriptionAttentionCard(subscription:)` sets the cached visibility to `false`
    /// and skips the API call when the feature flag is disabled.
    @Test
    func refreshSubscriptionAttentionCard_featureFlagDisabled() async {
        configService.featureFlagsBool[.premiumUpgradePath] = false

        await subject.refreshSubscriptionAttentionCard(subscription: nil)

        #expect(billingStateService.setSubscriptionAttentionCardVisibleReceivedVisible == false)
        #expect(!billingAPIService.getSubscriptionCalled)
    }

    /// `refreshSubscriptionAttentionCard(subscription:)` sets the cached visibility to `false`
    /// and does not log an error when the user has no personal subscription (free user).
    @Test
    func refreshSubscriptionAttentionCard_noSubscription() async {
        billingAPIService.getSubscriptionThrowableError = GetSubscriptionRequestError.noSubscription

        await subject.refreshSubscriptionAttentionCard(subscription: nil)

        #expect(billingStateService.setSubscriptionAttentionCardVisibleReceivedVisible == false)
        #expect(errorReporter.errors.isEmpty)
    }

    /// `refreshSubscriptionAttentionCard(subscription:)` sets the cached visibility to `false`
    /// and skips the API call when the user is self-hosted.
    @Test
    func refreshSubscriptionAttentionCard_selfHosted() async {
        environmentService.region = .selfHosted

        await subject.refreshSubscriptionAttentionCard(subscription: nil)

        #expect(billingStateService.setSubscriptionAttentionCardVisibleReceivedVisible == false)
        #expect(!billingAPIService.getSubscriptionCalled)
    }

    /// `refreshSubscriptionAttentionCard(subscription:)` sets the cached visibility based on
    /// whether the subscription status requires payment attention.
    @Test(arguments: [
        (SubscriptionStatus.pastDue, true),
        (SubscriptionStatus.unpaid, true),
        (SubscriptionStatus.active, false),
    ])
    func refreshSubscriptionAttentionCard_statusVisibility(
        status: SubscriptionStatus,
        expectedVisible: Bool,
    ) async {
        billingAPIService.getSubscriptionReturnValue = .fixture(status: status)

        await subject.refreshSubscriptionAttentionCard(subscription: nil)

        #expect(billingStateService.setSubscriptionAttentionCardVisibleReceivedVisible == expectedVisible)
    }

    /// `refreshSubscriptionAttentionCard(subscription:)` sets the cached visibility to `true`
    /// when a subscription with `.unpaid` status is provided directly (Plan screen path).
    @Test
    func refreshSubscriptionAttentionCard_unpaid_providedSubscription() async {
        await subject.refreshSubscriptionAttentionCard(subscription: .fixture(status: .unpaid))

        #expect(billingStateService.setSubscriptionAttentionCardVisibleReceivedVisible == true)
        #expect(!billingAPIService.getSubscriptionCalled)
    }

    /// `refreshSubscriptionAttentionCard(subscription:)` uses an already-fetched subscription
    /// instead of making a new API call when one is provided.
    @Test
    func refreshSubscriptionAttentionCard_usesProvidedSubscription() async {
        await subject.refreshSubscriptionAttentionCard(subscription: .fixture(status: .pastDue))

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
