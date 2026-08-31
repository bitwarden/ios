import BitwardenKitMocks
import Combine
import Foundation
import TestHelpers
import Testing

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - BillingServiceTests

// swiftlint:disable file_length

@MainActor
struct BillingServiceTests { // swiftlint:disable:this type_body_length
    // MARK: Properties

    var billingAPIService: MockBillingAPIService!
    var configService: MockConfigService!
    var environmentService: MockEnvironmentService!
    var errorReporter: MockErrorReporter!
    var stateService: MockStateService!
    var syncService: MockSyncService!
    var subject: DefaultBillingService!

    // MARK: Initialization

    init() {
        billingAPIService = MockBillingAPIService()
        billingAPIService.getSubscriptionReturnValue = .fixture()
        configService = MockConfigService()
        configService.featureFlagsBool[.premiumUpgradePath] = true
        environmentService = MockEnvironmentService()
        environmentService.region = .unitedStates
        errorReporter = MockErrorReporter()
        stateService = MockStateService()
        stateService.activeAccount = .fixture()
        syncService = MockSyncService()
        subject = DefaultBillingService(
            billingAPIService: billingAPIService,
            billingStateService: stateService,
            configService: configService,
            environmentService: environmentService,
            errorReporter: errorReporter,
            stateService: stateService,
            syncService: syncService,
            debounceInterval: .milliseconds(100),
        )
    }

    // MARK: Tests

    /// `createCheckoutSession()` returns the URL when it uses HTTPS scheme.
    @Test
    func createCheckoutSession_success() async throws {
        let expectedURL = URL(string: "https://checkout.stripe.com/session")!
        billingAPIService.createCheckoutSessionReturnValue = CheckoutSessionResponseModel(
            checkoutSessionUrl: expectedURL,
        )

        let result = try await subject.createCheckoutSession()

        #expect(billingAPIService.createCheckoutSessionCallsCount == 1)
        #expect(result == expectedURL)
    }

    /// `createCheckoutSession()` throws `invalidCheckoutUrl` when the URL uses HTTP scheme.
    @Test
    func createCheckoutSession_invalidUrl_http() async throws {
        let httpURL = URL(string: "http://checkout.stripe.com/session")!
        billingAPIService.createCheckoutSessionReturnValue = CheckoutSessionResponseModel(
            checkoutSessionUrl: httpURL,
        )

        await #expect(throws: BillingError.invalidCheckoutUrl) {
            _ = try await subject.createCheckoutSession()
        }

        #expect(billingAPIService.createCheckoutSessionCallsCount == 1)
    }

    /// `createCheckoutSession()` throws `invalidCheckoutUrl` when the URL has no scheme.
    @Test
    func createCheckoutSession_invalidUrl_noScheme() async throws {
        let noSchemeURL = URL(string: "checkout.stripe.com/session")!
        billingAPIService.createCheckoutSessionReturnValue = CheckoutSessionResponseModel(
            checkoutSessionUrl: noSchemeURL,
        )

        await #expect(throws: BillingError.invalidCheckoutUrl) {
            _ = try await subject.createCheckoutSession()
        }

        #expect(billingAPIService.createCheckoutSessionCallsCount == 1)
    }

    /// `createCheckoutSession()` propagates errors from the API service.
    @Test
    func createCheckoutSession_apiError() async throws {
        billingAPIService.createCheckoutSessionThrowableError = URLError(.notConnectedToInternet)

        await #expect(throws: URLError.self) {
            try await subject.createCheckoutSession()
        }

        #expect(billingAPIService.createCheckoutSessionCallsCount == 1)
    }

    /// `getPortalUrl()` returns the URL when it uses HTTPS scheme.
    @Test
    func getPortalUrl_success() async throws {
        let expectedURL = URL(string: "https://billing.stripe.com/portal/session")!
        billingAPIService.getPortalUrlReturnValue = .init(url: expectedURL)

        let result = try await subject.getPortalUrl()

        #expect(billingAPIService.getPortalUrlCallsCount == 1)
        #expect(result == expectedURL)
    }

    /// `getPortalUrl()` throws `invalidPortalUrl` when the URL uses HTTP scheme.
    @Test
    func getPortalUrl_nonHttpsUrl_throwsInvalidPortalUrl() async throws {
        let httpURL = URL(string: "http://billing.stripe.com/portal/session")!
        billingAPIService.getPortalUrlReturnValue = .init(url: httpURL)

        await #expect(throws: BillingError.invalidPortalUrl) {
            _ = try await subject.getPortalUrl()
        }

        #expect(billingAPIService.getPortalUrlCallsCount == 1)
    }

    /// `getPremiumPlan()` returns the Premium plan from the API service.
    @Test
    func getPremiumPlan_success() async throws {
        let expectedPlan = PremiumPlanResponseModel(
            available: true,
            legacyYear: nil,
            name: "Premium",
            seat: PlanPricingResponseModel(
                price: 19.80,
                provided: 0,
                stripePriceId: "premium-annually-2026",
            ),
            storage: PlanPricingResponseModel(
                price: 4,
                provided: 5,
                stripePriceId: "personal-storage-gb-annually",
            ),
        )
        billingAPIService.getPremiumPlanReturnValue = expectedPlan

        let result = try await subject.getPremiumPlan()

        #expect(billingAPIService.getPremiumPlanCallsCount == 1)
        #expect(result == expectedPlan)
    }

    /// `getPremiumPlan()` propagates errors from the API service.
    @Test
    func getPremiumPlan_apiError() async throws {
        billingAPIService.getPremiumPlanThrowableError = URLError(.notConnectedToInternet)

        await #expect(throws: URLError.self) {
            try await subject.getPremiumPlan()
        }

        #expect(billingAPIService.getPremiumPlanCallsCount == 1)
    }

    /// `getSubscription()` propagates errors from the API service.
    @Test
    func getSubscription_apiError() async throws {
        billingAPIService.getSubscriptionThrowableError = URLError(.notConnectedToInternet)

        await #expect(throws: URLError.self) {
            try await subject.getSubscription()
        }

        #expect(billingAPIService.getSubscriptionCallsCount == 1)
    }

    /// `getSubscription()` maps canceled status correctly.
    @Test
    func getSubscription_canceled() async throws {
        billingAPIService.getSubscriptionReturnValue = .fixture(
            canceled: Date(timeIntervalSince1970: 1_800_000_000),
            status: .canceled,
        )

        let result = try await subject.getSubscription()

        #expect(result.status == .canceled)
        #expect(result.canceled != nil)
    }

    /// `getSubscription()` includes cart-level discount in the total discount.
    @Test
    func getSubscription_cartDiscount() async throws {
        billingAPIService.getSubscriptionReturnValue = .fixture(
            cart: .fixture(
                discount: BitwardenDiscountResponseModel(type: .amountOff, value: 5),
                passwordManager: PasswordManagerCartItemsResponseModel(
                    additionalStorage: nil,
                    seats: CartItemResponseModel(
                        cost: 20,
                        discount: nil,
                        quantity: 1,
                        translationKey: "premiumMembership",
                    ),
                ),
            ),
        )

        let result = try await subject.getSubscription()

        #expect(result.discount == 5)
    }

    /// `getSubscription()` maps past_due status correctly.
    @Test
    func getSubscription_pastDue() async throws {
        billingAPIService.getSubscriptionReturnValue = .fixture(
            gracePeriod: 14,
            status: .pastDue,
            suspension: Date(timeIntervalSince1970: 1_803_219_691),
        )

        let result = try await subject.getSubscription()

        #expect(result.status == .pastDue)
        #expect(result.gracePeriod == 14)
        #expect(result.suspension != nil)
    }

    /// `getSubscription()` maps the API response to a `PremiumSubscription` domain model.
    @Test
    func getSubscription_success() async throws {
        billingAPIService.getSubscriptionReturnValue = .fixture(
            cart: .fixture(
                estimatedTax: 4.55,
                passwordManager: PasswordManagerCartItemsResponseModel(
                    additionalStorage: CartItemResponseModel(
                        cost: 4,
                        discount: nil,
                        quantity: 2,
                        translationKey: "additionalStorage",
                    ),
                    seats: CartItemResponseModel(
                        cost: 19.8,
                        discount: BitwardenDiscountResponseModel(type: .percentOff, value: 10),
                        quantity: 1,
                        translationKey: "premiumMembership",
                    ),
                ),
            ),
            gracePeriod: 14,
            nextCharge: Date(timeIntervalSince1970: 1_803_219_691),
        )

        let result = try await subject.getSubscription()

        #expect(billingAPIService.getSubscriptionCallsCount == 1)
        #expect(result.cadence == .annually)
        #expect(result.seatsCost == 19.8)
        #expect(result.storageCost == 8)
        #expect(result.discount == 1.98)
        #expect(result.estimatedTax == 4.55)
        #expect(result.gracePeriod == 14)
        #expect(result.status == .active)
        #expect(result.nextCharge != nil)
    }

    /// `getSubscription()` maps unpaid status to its own `.unpaid` plan status.
    @Test
    func getSubscription_unpaid() async throws {
        billingAPIService.getSubscriptionReturnValue = .fixture(
            cancelAt: Date(timeIntervalSince1970: 1_803_219_691),
            status: .unpaid,
        )

        let result = try await subject.getSubscription()

        #expect(result.status == .unpaid)
        #expect(result.cancelAt != nil)
    }

    /// `premiumCheckoutCanceled()` publishes `.canceled` and then resets the publisher value to nil.
    @Test
    func premiumCheckoutCanceled() async throws {
        var statuses = [PremiumCheckoutStatus]()
        let cancellable = subject.premiumCheckoutStatusPublisher()
            .sink { statuses.append($0) }
        defer { cancellable.cancel() }

        subject.premiumCheckoutCanceled()

        try await waitForAsync { !statuses.isEmpty }
        #expect(statuses == [.canceled])

        // After .canceled + nil are sent, a new subscriber should receive nothing (nil is filtered).
        var lateStatuses = [PremiumCheckoutStatus]()
        let lateCancellable = subject.premiumCheckoutStatusPublisher()
            .sink { lateStatuses.append($0) }
        defer { lateCancellable.cancel() }
        try await waitForAsync { lateStatuses.isEmpty }
    }

    /// `premiumStatusChanged()` returns early without syncing when the user already has Premium.
    @Test
    func premiumStatusChanged_alreadyHasPremium() async throws {
        stateService.doesActiveAccountHavePremiumResult = true
        var statuses = [PremiumCheckoutStatus]()
        let cancellable = subject.premiumCheckoutStatusPublisher()
            .sink { statuses.append($0) }
        defer { cancellable.cancel() }

        await subject.premiumStatusChanged()

        #expect(statuses.isEmpty)
        #expect(!syncService.didFetchSync)
    }

    /// `premiumStatusChanged()` publishes `.confirmed` when the user gains Premium after sync.
    @Test
    func premiumStatusChanged_confirmed() async throws {
        // Start as non-Premium so the guard passes, then switch to Premium after sync.
        stateService.doesActiveAccountHavePremiumResult = false
        syncService.fetchSyncHandler = {
            stateService.doesActiveAccountHavePremiumResult = true
        }
        var statuses = [PremiumCheckoutStatus]()
        let cancellable = subject.premiumCheckoutStatusPublisher()
            .sink { statuses.append($0) }
        defer { cancellable.cancel() }

        await subject.premiumStatusChanged()

        // With instant mock sync, .syncing and .confirmed arrive within the 300ms debounce
        // window, so only .confirmed (the last value) is delivered.
        try await waitForAsync { !statuses.isEmpty }
        #expect(statuses == [.confirmed])
        #expect(syncService.didFetchSync)
    }

    /// `premiumStatusChanged()` resets the publisher value to nil after emitting `.confirmed`,
    /// so late subscribers do not receive a stale `.confirmed` on connection.
    @Test
    func premiumStatusChanged_confirmed_resetsPublisherValue() async throws {
        stateService.doesActiveAccountHavePremiumResult = false
        syncService.fetchSyncHandler = {
            stateService.doesActiveAccountHavePremiumResult = true
        }
        var earlyStatuses = [PremiumCheckoutStatus]()
        let earlyCancellable = subject.premiumCheckoutStatusPublisher()
            .sink { earlyStatuses.append($0) }
        defer { earlyCancellable.cancel() }

        await subject.premiumStatusChanged()
        try await waitForAsync { !earlyStatuses.isEmpty }

        // A subscriber connecting after .confirmed + nil are emitted should receive nothing.
        var lateStatuses = [PremiumCheckoutStatus]()
        let lateCancellable = subject.premiumCheckoutStatusPublisher()
            .sink { lateStatuses.append($0) }
        defer { lateCancellable.cancel() }

        try await waitForAsync { lateStatuses.isEmpty }
    }

    /// `premiumStatusChanged()` returns early without syncing when the premiumUpgradePath flag is disabled.
    @Test
    func premiumStatusChanged_featureFlagDisabled() async throws {
        configService.featureFlagsBool[.premiumUpgradePath] = false
        stateService.doesActiveAccountHavePremiumResult = false
        var statuses = [PremiumCheckoutStatus]()
        let cancellable = subject.premiumCheckoutStatusPublisher()
            .sink { statuses.append($0) }
        defer { cancellable.cancel() }

        await subject.premiumStatusChanged()

        #expect(statuses.isEmpty)
        #expect(!syncService.didFetchSync)
    }

    /// `premiumStatusChanged()` publishes `.pending` when the user does not have Premium after sync.
    @Test
    func premiumStatusChanged_pending() async throws {
        stateService.doesActiveAccountHavePremiumResult = false
        var statuses = [PremiumCheckoutStatus]()
        let cancellable = subject.premiumCheckoutStatusPublisher()
            .sink { statuses.append($0) }
        defer { cancellable.cancel() }

        await subject.premiumStatusChanged()

        try await waitForAsync { !statuses.isEmpty }
        #expect(statuses == [.pending])
        #expect(syncService.didFetchSync)
    }

    /// `isSelfHosted()` returns `false` when the region is not self-hosted.
    @Test
    func isSelfHosted_cloudRegion_returnsFalse() async {
        environmentService.region = .unitedStates

        let result = await subject.isSelfHosted()

        #expect(result == false)
    }

    /// `isSelfHosted()` returns `true` when self-hosted and the debug flag is off.
    @Test
    func isSelfHosted_selfHostedRegion_debugFlagOff_returnsTrue() async {
        environmentService.region = .selfHosted
        configService.featureFlagsBool[.debugDisableSelfHostPremiumCheck] = false

        let result = await subject.isSelfHosted()

        #expect(result == true)
    }

    /// `isSelfHosted()` returns `false` when self-hosted but the debug override flag is enabled.
    @Test
    func isSelfHosted_selfHostedRegion_debugFlagOn_returnsFalse() async {
        environmentService.region = .selfHosted
        configService.featureFlagsBool[.debugDisableSelfHostPremiumCheck] = true

        let result = await subject.isSelfHosted()

        #expect(result == false)
    }

    /// `isSelfHosted()` returns `true` for the internal QA region (any `bitwarden.pw` host) when
    /// the debug flag is off, matching how `.internal` is treated as self-hosted elsewhere.
    @Test
    func isSelfHosted_internalRegion_debugFlagOff_returnsTrue() async {
        environmentService.region = .internal
        configService.featureFlagsBool[.debugDisableSelfHostPremiumCheck] = false

        let result = await subject.isSelfHosted()

        #expect(result == true)
    }

    /// `isSelfHosted()` returns `false` for the internal QA region when the debug override flag is enabled.
    @Test
    func isSelfHosted_internalRegion_debugFlagOn_returnsFalse() async {
        environmentService.region = .internal
        configService.featureFlagsBool[.debugDisableSelfHostPremiumCheck] = true

        let result = await subject.isSelfHosted()

        #expect(result == false)
    }

    /// `premiumStatusChanged()` returns early without syncing when the environment is self-hosted.
    @Test
    func premiumStatusChanged_selfHosted() async throws {
        environmentService.region = .selfHosted
        stateService.doesActiveAccountHavePremiumResult = false
        var statuses = [PremiumCheckoutStatus]()
        let cancellable = subject.premiumCheckoutStatusPublisher()
            .sink { statuses.append($0) }
        defer { cancellable.cancel() }

        await subject.premiumStatusChanged()

        #expect(statuses.isEmpty)
        #expect(!syncService.didFetchSync)
    }

    /// `premiumStatusChanged()` syncs when self-hosted region is overridden by the debug flag.
    @Test
    func premiumStatusChanged_selfHosted_debugFlagEnabled_syncs() async throws {
        environmentService.region = .selfHosted
        configService.featureFlagsBool[.debugDisableSelfHostPremiumCheck] = true
        stateService.doesActiveAccountHavePremiumResult = false
        var statuses = [PremiumCheckoutStatus]()
        let cancellable = subject.premiumCheckoutStatusPublisher()
            .sink { statuses.append($0) }
        defer { cancellable.cancel() }

        await subject.premiumStatusChanged()

        try await waitForAsync { !statuses.isEmpty }
        #expect(syncService.didFetchSync)
    }

    /// `setUpgradedToPremiumActionCardDismissed()` sets the visibility flag to `false` for the active account.
    @Test
    func setUpgradedToPremiumActionCardDismissed() async {
        stateService.upgradedToPremiumActionCardVisibleResult = true

        await subject.setUpgradedToPremiumActionCardDismissed()

        #expect(stateService.upgradedToPremiumActionCardVisibleResult == false)
    }

    /// `setUpgradedToPremiumActionCardDismissed()` logs an error if the state service throws.
    @Test
    func setUpgradedToPremiumActionCardDismissed_error() async {
        stateService.setUpgradedToPremiumActionCardResult = .failure(StateServiceError.noActiveAccount)

        await subject.setUpgradedToPremiumActionCardDismissed()

        #expect(errorReporter.errors.first as? StateServiceError == .noActiveAccount)
    }

    /// `shouldShowUpgradedToPremiumActionCard()` returns `true` when the state service reports the card is visible.
    @Test
    func shouldShowUpgradedToPremiumActionCard_visible() async {
        stateService.upgradedToPremiumActionCardVisibleResult = true

        let result = await subject.shouldShowUpgradedToPremiumActionCard()

        #expect(result == true)
    }

    /// `shouldShowUpgradedToPremiumActionCard()` returns `false` when the state service reports it is not visible.
    @Test
    func shouldShowUpgradedToPremiumActionCard_notVisible() async {
        stateService.upgradedToPremiumActionCardVisibleResult = false

        let result = await subject.shouldShowUpgradedToPremiumActionCard()

        #expect(result == false)
    }

    /// `premiumStatusChanged()` reports the error and publishes `.pending` when sync fails.
    @Test
    func premiumStatusChanged_syncError() async throws {
        stateService.doesActiveAccountHavePremiumResult = false
        syncService.fetchSyncResult = .failure(URLError(.notConnectedToInternet))
        var statuses = [PremiumCheckoutStatus]()
        let cancellable = subject.premiumCheckoutStatusPublisher()
            .sink { statuses.append($0) }
        defer { cancellable.cancel() }

        await subject.premiumStatusChanged()

        try await waitForAsync { !statuses.isEmpty }
        #expect(statuses == [.pending])
        #expect(errorReporter.errors.first is URLError)
    }

    // MARK: refreshSubscriptionAttentionCard

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

        #expect(stateService.subscriptionAttentionCardVisibleResult == expectedVisible)
    }

    /// `refreshSubscriptionAttentionCard(subscription:)` sets the cached visibility to `false`
    /// and skips the API call when the user is self-hosted.
    @Test
    func refreshSubscriptionAttentionCard_selfHosted() async {
        environmentService.region = .selfHosted

        await subject.refreshSubscriptionAttentionCard(subscription: nil)

        #expect(stateService.subscriptionAttentionCardVisibleResult == false)
        #expect(!billingAPIService.getSubscriptionCalled)
    }

    /// `refreshSubscriptionAttentionCard(subscription:)` sets the cached visibility to `false`
    /// and skips the API call when the feature flag is disabled.
    @Test
    func refreshSubscriptionAttentionCard_featureFlagDisabled() async {
        configService.featureFlagsBool[.premiumUpgradePath] = false

        await subject.refreshSubscriptionAttentionCard(subscription: nil)

        #expect(stateService.subscriptionAttentionCardVisibleResult == false)
        #expect(!billingAPIService.getSubscriptionCalled)
    }

    /// `refreshSubscriptionAttentionCard(subscription:)` sets the cached visibility to `false`
    /// and does not log an error when the user has no personal subscription (free user).
    @Test
    func refreshSubscriptionAttentionCard_noSubscription() async {
        billingAPIService.getSubscriptionThrowableError = GetSubscriptionRequestError.noSubscription

        await subject.refreshSubscriptionAttentionCard(subscription: nil)

        #expect(stateService.subscriptionAttentionCardVisibleResult == false)
        #expect(errorReporter.errors.isEmpty)
    }

    /// `refreshSubscriptionAttentionCard(subscription:)` uses an already-fetched subscription
    /// instead of making a new API call when one is provided.
    @Test
    func refreshSubscriptionAttentionCard_usesProvidedSubscription() async {
        await subject.refreshSubscriptionAttentionCard(subscription: .fixture(status: .pastDue))

        #expect(stateService.subscriptionAttentionCardVisibleResult == true)
        #expect(!billingAPIService.getSubscriptionCalled)
    }

    /// `refreshSubscriptionAttentionCard(subscription:)` sets the cached visibility to `true`
    /// when a subscription with `.unpaid` status is provided directly (Plan screen path).
    @Test
    func refreshSubscriptionAttentionCard_unpaid_providedSubscription() async {
        await subject.refreshSubscriptionAttentionCard(subscription: .fixture(status: .unpaid))

        #expect(stateService.subscriptionAttentionCardVisibleResult == true)
        #expect(!billingAPIService.getSubscriptionCalled)
    }

    /// `refreshSubscriptionAttentionCard(subscription:)` logs the error and does not update
    /// the cache when the API call fails.
    @Test
    func refreshSubscriptionAttentionCard_apiError() async {
        billingAPIService.getSubscriptionThrowableError = URLError(.notConnectedToInternet)

        await subject.refreshSubscriptionAttentionCard(subscription: nil)

        #expect(stateService.subscriptionAttentionCardVisibleResult == false)
        #expect(errorReporter.errors.first is URLError)
    }

    // MARK: shouldShowSubscriptionAttentionCard

    /// `shouldShowSubscriptionAttentionCard()` returns the cached value without making an API call.
    @Test
    func shouldShowSubscriptionAttentionCard_returnsFromCache() async {
        stateService.subscriptionAttentionCardVisibleResult = true

        let result = await subject.shouldShowSubscriptionAttentionCard()

        #expect(result)
        #expect(!billingAPIService.getSubscriptionCalled)
    }

    // MARK: premiumUpgradePendingState

    /// `premiumUpgradePendingState()` reflects the persisted pending/failure flags for the active account.
    @Test
    func premiumUpgradePendingState_reflectsPersistedFlags() async {
        stateService.premiumUpgradePendingByUserId["1"] = true
        stateService.premiumUpgradeSyncAttemptFailedByUserId["1"] = true

        let result = await subject.premiumUpgradePendingState()

        #expect(result == PremiumUpgradePendingState(isPending: true, lastAttemptFailed: true))
    }

    /// `premiumUpgradePendingState()` returns a default, non-pending state and logs the error
    /// when the state service can't resolve the active account.
    @Test
    func premiumUpgradePendingState_error() async {
        stateService.activeAccount = nil

        let result = await subject.premiumUpgradePendingState()

        #expect(result == PremiumUpgradePendingState(isPending: false, lastAttemptFailed: false))
        #expect(errorReporter.errors.first as? StateServiceError == .noActiveAccount)
    }

    // MARK: reconcileCheckoutSuccess

    /// `reconcileCheckoutSuccess()` marks the upgrade pending, syncs, and publishes `.confirmed`
    /// when the sync confirms Premium.
    @Test
    func reconcileCheckoutSuccess_confirmed() async throws {
        stateService.doesAccountHavePremiumByUserId["1"] = false
        syncService.fetchSyncHandler = {
            stateService.doesAccountHavePremiumByUserId["1"] = true
        }
        var statuses = [PremiumCheckoutStatus]()
        let cancellable = subject.premiumCheckoutStatusPublisher()
            .sink { statuses.append($0) }
        defer { cancellable.cancel() }

        await subject.reconcileCheckoutSuccess()

        try await waitForAsync { !statuses.isEmpty }
        #expect(statuses == [.confirmed])
        #expect(syncService.didFetchSync)
        #expect(stateService.premiumUpgradePendingByUserId["1"] == false)
        #expect(stateService.premiumUpgradeSyncAttemptFailedByUserId["1"] == false)
        #expect(stateService.upgradedToPremiumCardVisibleByUserId["1"] == true)
    }

    /// `reconcileCheckoutSuccess()` leaves the upgrade pending and publishes `.pending` when the
    /// sync succeeds but Premium hasn't been granted yet.
    @Test
    func reconcileCheckoutSuccess_pending() async throws {
        stateService.doesAccountHavePremiumByUserId["1"] = false
        var statuses = [PremiumCheckoutStatus]()
        let cancellable = subject.premiumCheckoutStatusPublisher()
            .sink { statuses.append($0) }
        defer { cancellable.cancel() }

        await subject.reconcileCheckoutSuccess()

        try await waitForAsync { !statuses.isEmpty }
        #expect(statuses == [.pending])
        #expect(stateService.premiumUpgradePendingByUserId["1"] == true)
        #expect(stateService.premiumUpgradeSyncAttemptFailedByUserId["1"] == false)
    }

    /// `reconcileCheckoutSuccess()` records a sync failure (leaving the upgrade pending so a
    /// later sync can retry) and publishes `.pending` when the forced sync throws.
    @Test
    func reconcileCheckoutSuccess_syncError() async throws {
        stateService.doesAccountHavePremiumByUserId["1"] = false
        syncService.fetchSyncResult = .failure(URLError(.notConnectedToInternet))
        var statuses = [PremiumCheckoutStatus]()
        let cancellable = subject.premiumCheckoutStatusPublisher()
            .sink { statuses.append($0) }
        defer { cancellable.cancel() }

        await subject.reconcileCheckoutSuccess()

        try await waitForAsync { !statuses.isEmpty }
        #expect(statuses == [.pending])
        #expect(errorReporter.errors.first is URLError)
        #expect(stateService.premiumUpgradePendingByUserId["1"] == true)
        #expect(stateService.premiumUpgradeSyncAttemptFailedByUserId["1"] == true)
    }

    /// `reconcileCheckoutSuccess()` never records a sync failure once Premium is confirmed, even
    /// if the sync that granted it later throws on an unrelated step.
    @Test
    func reconcileCheckoutSuccess_syncErrorAfterPremiumConfirmed() async throws {
        stateService.doesAccountHavePremiumByUserId["1"] = false
        syncService.fetchSyncHandler = {
            stateService.doesAccountHavePremiumByUserId["1"] = true
        }
        syncService.fetchSyncResult = .failure(URLError(.notConnectedToInternet))

        await subject.reconcileCheckoutSuccess()

        #expect(stateService.premiumUpgradeSyncAttemptFailedByUserId["1"] == false)
        #expect(stateService.premiumUpgradePendingByUserId["1"] == false)
        #expect(stateService.upgradedToPremiumCardVisibleByUserId["1"] == true)
    }

    /// `reconcileCheckoutSuccess()` does nothing when the environment is self-hosted.
    @Test
    func reconcileCheckoutSuccess_selfHosted_doesNothing() async {
        environmentService.region = .selfHosted

        await subject.reconcileCheckoutSuccess()

        #expect(!syncService.didFetchSync)
        #expect(stateService.premiumUpgradePendingByUserId["1"] == nil)
    }

    /// `reconcileCheckoutSuccess()` does nothing when the premiumUpgradePath feature flag is disabled.
    @Test
    func reconcileCheckoutSuccess_featureFlagDisabled_doesNothing() async {
        configService.featureFlagsBool[.premiumUpgradePath] = false

        await subject.reconcileCheckoutSuccess()

        #expect(!syncService.didFetchSync)
        #expect(stateService.premiumUpgradePendingByUserId["1"] == nil)
    }

    /// `reconcileCheckoutSuccess()` does nothing when there's no active account to reconcile for.
    @Test
    func reconcileCheckoutSuccess_noActiveAccount_doesNothing() async {
        stateService.activeAccount = nil

        await subject.reconcileCheckoutSuccess()

        #expect(!syncService.didFetchSync)
    }

    /// `reconcileCheckoutSuccess()` still persists the correct result for the account it started
    /// for, even if the active account switches away while its forced sync is in flight — and
    /// doesn't publish a checkout status meant for the now-active (unrelated) account.
    @Test
    func reconcileCheckoutSuccess_accountSwitchedDuringSync_writesOriginalAccountOnly() async throws {
        stateService.doesAccountHavePremiumByUserId["1"] = false
        syncService.fetchSyncHandler = {
            stateService.doesAccountHavePremiumByUserId["1"] = true
            stateService.activeAccount = .fixture(profile: .fixture(userId: "2"))
        }
        var statuses = [PremiumCheckoutStatus]()
        let cancellable = subject.premiumCheckoutStatusPublisher()
            .sink { statuses.append($0) }
        defer { cancellable.cancel() }

        await subject.reconcileCheckoutSuccess()

        #expect(statuses.isEmpty)
        #expect(stateService.premiumUpgradePendingByUserId["1"] == false)
        #expect(stateService.upgradedToPremiumCardVisibleByUserId["1"] == true)
        #expect(stateService.premiumUpgradePendingByUserId["2"] == nil)
        #expect(stateService.upgradedToPremiumCardVisibleByUserId["2"] == nil)
    }

    /// `reconcileCheckoutSuccess()` still reports `.confirmed` when the pending flags it set are
    /// already cleared by the time its own resolution step runs — e.g. `start()`'s background
    /// sync watcher reacting to this same forced sync and resolving it first. Regression test for
    /// `resolvePendingUpgrade(userId:syncFailed:)`'s early-exit branch, which used to return a
    /// hardcoded `false` in this situation regardless of the account's actual Premium status.
    @Test
    func reconcileCheckoutSuccess_alreadyResolvedByConcurrentSync_stillReportsConfirmed() async throws {
        stateService.doesAccountHavePremiumByUserId["1"] = false
        syncService.fetchSyncHandler = {
            // Simulates `start()`'s background watcher (`reconcileOnEachNewSync(userId:)`)
            // reacting to this same sync and resolving the pending upgrade before this call's own
            // `resolvePendingUpgrade(userId:syncFailed:)` runs.
            stateService.doesAccountHavePremiumByUserId["1"] = true
            stateService.premiumUpgradePendingByUserId["1"] = false
            stateService.premiumUpgradeSyncAttemptFailedByUserId["1"] = false
        }
        var statuses = [PremiumCheckoutStatus]()
        let cancellable = subject.premiumCheckoutStatusPublisher()
            .sink { statuses.append($0) }
        defer { cancellable.cancel() }

        await subject.reconcileCheckoutSuccess()

        try await waitForAsync { !statuses.isEmpty }
        #expect(statuses == [.confirmed])
    }

    // MARK: start

    /// `start()` resolves a pending upgrade the moment it starts observing an account that
    /// already has one recorded (e.g. left over from a previous app session).
    @Test
    func start_resolvesExistingPendingUpgradeOnFirstSync() async throws {
        stateService.premiumUpgradePendingByUserId["1"] = true
        stateService.doesAccountHavePremiumByUserId["1"] = true

        await subject.start()
        stateService.lastSyncTimeSubject.send(Date())

        try await waitForAsync { stateService.premiumUpgradePendingByUserId["1"] == false }
        #expect(stateService.upgradedToPremiumCardVisibleByUserId["1"] == true)
    }

    /// `start()` resolves a pending upgrade on a later, unrelated sync — not just the sync that
    /// originated the checkout attempt (the "delayed sync" case: Settings > Sync Now, or a sync
    /// triggered from the web vault).
    @Test
    func start_resolvesPendingUpgradeOnDelayedSync() async throws {
        await subject.start()

        stateService.premiumUpgradePendingByUserId["1"] = true
        stateService.doesAccountHavePremiumByUserId["1"] = false
        stateService.lastSyncTimeSubject.send(Date())
        try await waitForAsync { stateService.premiumUpgradeSyncAttemptFailedByUserId["1"] == false }
        #expect(stateService.premiumUpgradePendingByUserId["1"] == true)

        stateService.doesAccountHavePremiumByUserId["1"] = true
        stateService.lastSyncTimeSubject.send(Date(timeIntervalSinceNow: 1))

        try await waitForAsync { stateService.premiumUpgradePendingByUserId["1"] == false }
        #expect(stateService.upgradedToPremiumCardVisibleByUserId["1"] == true)
    }

    /// `start()`'s background sync watcher leaves an account with no pending upgrade (and no
    /// prior failure) untouched, so a normal sync for a long-since-Premium or free account never
    /// spuriously shows the "Upgraded to Premium" card.
    @Test
    func start_ignoresSyncsWithNoPendingUpgrade() async throws {
        stateService.doesAccountHavePremiumByUserId["1"] = true

        await subject.start()
        stateService.lastSyncTimeSubject.send(Date())

        // Give the background watcher a chance to (not) act before asserting nothing changed.
        try await Task.sleep(nanoseconds: 50_000_000)
        #expect(stateService.premiumUpgradePendingByUserId["1"] == nil)
        #expect(stateService.upgradedToPremiumCardVisibleByUserId["1"] == nil)
    }

    /// `start()` only subscribes once, ignoring subsequent calls.
    @Test
    func start_subscribesOnlyOnce() async throws {
        stateService.premiumUpgradePendingByUserId["1"] = true
        stateService.doesAccountHavePremiumByUserId["1"] = true

        await subject.start()
        await subject.start()
        stateService.lastSyncTimeSubject.send(Date())

        try await waitForAsync { stateService.premiumUpgradePendingByUserId["1"] == false }
    }

    // MARK: premiumUpgradePendingStatePublisher

    /// `premiumUpgradePendingStatePublisher()` replays the current state to a new subscriber
    /// immediately, then re-emits it as `reconcileCheckoutSuccess()` refreshes it: once pending,
    /// right before its forced sync, and again once resolved after the sync confirms Premium.
    @Test
    func premiumUpgradePendingStatePublisher_emitsOnReconcileCheckoutSuccess() async throws {
        stateService.doesAccountHavePremiumByUserId["1"] = false
        syncService.fetchSyncHandler = {
            stateService.doesAccountHavePremiumByUserId["1"] = true
        }
        var states = [PremiumUpgradePendingState]()
        let cancellable = subject.premiumUpgradePendingStatePublisher()
            .sink { states.append($0) }
        defer { cancellable.cancel() }

        try await waitForAsync { !states.isEmpty }

        await subject.reconcileCheckoutSuccess()

        try await waitForAsync { states.count == 3 }
        #expect(states == [
            PremiumUpgradePendingState(isPending: false, lastAttemptFailed: false),
            PremiumUpgradePendingState(isPending: true, lastAttemptFailed: false),
            PremiumUpgradePendingState(isPending: false, lastAttemptFailed: false),
        ])
    }

    /// `start()` resets `premiumUpgradePendingStatePublisher()` to the default, non-pending state
    /// the instant the active account logs out, as a direct push rather than a
    /// `billingStateService` read — the logged-out account's own persisted flags are left
    /// untouched for whenever it's active again.
    @Test
    func premiumUpgradePendingStatePublisher_resetsOnLogout() async throws {
        var states = [PremiumUpgradePendingState]()
        let cancellable = subject.premiumUpgradePendingStatePublisher()
            .sink { states.append($0) }
        defer { cancellable.cancel() }

        await subject.start()
        try await waitForAsync { states.count == 2 }

        stateService.premiumUpgradePendingByUserId["1"] = true
        stateService.doesAccountHavePremiumByUserId["1"] = false
        stateService.lastSyncTimeSubject.send(Date())
        try await waitForAsync { states.count == 3 }
        #expect(states.last == PremiumUpgradePendingState(isPending: true, lastAttemptFailed: false))

        stateService.activeIdSubject.send(nil)

        try await waitForAsync { states.count == 4 }
        #expect(states.last == PremiumUpgradePendingState(isPending: false, lastAttemptFailed: false))
        #expect(stateService.premiumUpgradePendingByUserId["1"] == true)
    }
}
