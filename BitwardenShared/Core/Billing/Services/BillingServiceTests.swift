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

    /// `createCheckoutSession()` clears a stale `lastAttemptFailed` flag left over from a prior
    /// attempt before starting a new one.
    @Test
    func createCheckoutSession_clearsLastAttemptFailed() async throws {
        stateService.premiumUpgradeLastSyncAttemptFailedResult = true
        billingAPIService.createCheckoutSessionReturnValue = CheckoutSessionResponseModel(
            checkoutSessionUrl: URL(string: "https://checkout.stripe.com/session")!,
        )

        _ = try await subject.createCheckoutSession()

        #expect(stateService.premiumUpgradeLastSyncAttemptFailedResult == false)
    }

    /// `createCheckoutSession()` marks the upgrade as pending — this is the only place that
    /// happens, so a `.premiumStatusChanged` push for an account that never started a checkout
    /// has nothing to act on.
    @Test
    func createCheckoutSession_marksPending() async throws {
        billingAPIService.createCheckoutSessionReturnValue = CheckoutSessionResponseModel(
            checkoutSessionUrl: URL(string: "https://checkout.stripe.com/session")!,
        )

        _ = try await subject.createCheckoutSession()

        #expect(stateService.premiumUpgradePendingResult == true)
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

        await subject.premiumCheckoutCanceled()

        try await waitForAsync { !statuses.isEmpty }
        #expect(statuses == [.canceled])

        // After .canceled + nil are sent, a new subscriber should receive nothing (nil is filtered).
        var lateStatuses = [PremiumCheckoutStatus]()
        let lateCancellable = subject.premiumCheckoutStatusPublisher()
            .sink { lateStatuses.append($0) }
        defer { lateCancellable.cancel() }
        try await waitForAsync { lateStatuses.isEmpty }
    }

    /// `premiumCheckoutCanceled()` clears the pending mark `createCheckoutSession()` made for
    /// this attempt — no attempt is actually in flight anymore once the user cancels.
    @Test
    func premiumCheckoutCanceled_clearsPending() async throws {
        stateService.premiumUpgradePendingResult = true

        await subject.premiumCheckoutCanceled()

        #expect(stateService.premiumUpgradePendingResult == false)
    }

    /// A subscriber connecting after `.pending` is emitted receives the pending status immediately
    /// (CurrentValueSubject replays the last value to new subscribers).
    @Test
    func premiumCheckoutStatusPublisher_lateSubscriberReceivesPendingStatus() async throws {
        stateService.premiumUpgradePendingResult = true
        stateService.doesActiveAccountHavePremiumResult = false
        var earlyStatuses = [PremiumCheckoutStatus]()
        let earlyCancellable = subject.premiumCheckoutStatusPublisher()
            .sink { earlyStatuses.append($0) }

        await subject.premiumStatusChanged()
        try await waitForAsync { !earlyStatuses.isEmpty }

        // Late subscriber connects after .pending was emitted and should receive it.
        var lateStatuses = [PremiumCheckoutStatus]()
        let lateCancellable = subject.premiumCheckoutStatusPublisher()
            .sink { lateStatuses.append($0) }
        try await waitForAsync { !lateStatuses.isEmpty }

        #expect(lateStatuses == [.pending])
        _ = earlyCancellable
        _ = lateCancellable
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
        stateService.premiumUpgradePendingResult = true
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
        stateService.premiumUpgradePendingResult = true
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
        stateService.premiumUpgradePendingResult = true
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
        stateService.premiumUpgradePendingResult = true
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
        stateService.premiumUpgradePendingResult = true
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

    /// `premiumStatusChanged()` records the sync failure and marks the upgrade pending when
    /// `fetchSync` throws, and publishes the updated `PremiumUpgradePendingState`.
    @Test
    func premiumStatusChanged_syncError_recordsFailureAndPending() async throws {
        stateService.premiumUpgradePendingResult = true
        stateService.doesActiveAccountHavePremiumResult = false
        syncService.fetchSyncResult = .failure(URLError(.notConnectedToInternet))
        var pendingStates = [PremiumUpgradePendingState]()
        let cancellable = subject.premiumUpgradePendingStatePublisher()
            .sink { pendingStates.append($0) }
        defer { cancellable.cancel() }

        await subject.premiumStatusChanged()

        #expect(stateService.premiumUpgradeLastSyncAttemptFailedResult == true)
        #expect(stateService.premiumUpgradePendingResult == true)
        #expect(pendingStates.last == PremiumUpgradePendingState(isPending: true, lastAttemptFailed: true))
    }

    /// `premiumStatusChanged()` marks the upgrade pending without recording a failure when sync
    /// succeeds but the user is still not Premium.
    @Test
    func premiumStatusChanged_pending_noFailureRecorded() async throws {
        stateService.premiumUpgradePendingResult = true
        stateService.premiumUpgradeLastSyncAttemptFailedResult = true
        stateService.doesActiveAccountHavePremiumResult = false

        await subject.premiumStatusChanged()

        #expect(stateService.premiumUpgradeLastSyncAttemptFailedResult == false)
        #expect(stateService.premiumUpgradePendingResult == true)
    }

    /// `premiumStatusChanged()` does nothing when no upgrade is pending — this is the boundary
    /// that keeps a `.premiumStatusChanged` push notification (which isn't tied to any local
    /// checkout attempt) from marking an account pending just because it happens to not be
    /// Premium yet.
    @Test
    func premiumStatusChanged_notPending_doesNothing() async throws {
        stateService.premiumUpgradePendingResult = false
        stateService.doesActiveAccountHavePremiumResult = false
        var statuses = [PremiumCheckoutStatus]()
        let cancellable = subject.premiumCheckoutStatusPublisher()
            .sink { statuses.append($0) }
        defer { cancellable.cancel() }

        await subject.premiumStatusChanged()

        #expect(statuses.isEmpty)
        #expect(!syncService.didFetchSync)
        #expect(stateService.premiumUpgradePendingResult == false)
    }

    /// `premiumStatusChanged()` clears both the pending and failure flags once the user is
    /// confirmed Premium.
    @Test
    func premiumStatusChanged_confirmed_clearsPendingState() async throws {
        stateService.premiumUpgradePendingResult = true
        stateService.premiumUpgradeLastSyncAttemptFailedResult = true
        stateService.doesActiveAccountHavePremiumResult = false
        syncService.fetchSyncHandler = {
            stateService.doesActiveAccountHavePremiumResult = true
        }

        await subject.premiumStatusChanged()

        #expect(stateService.premiumUpgradePendingResult == false)
        #expect(stateService.premiumUpgradeLastSyncAttemptFailedResult == false)
    }

    // MARK: start()

    /// `start()` clears a stale `lastAttemptFailed` flag as soon as any sync succeeds, even
    /// when the active account still isn't Premium yet — a later, unrelated sync succeeding
    /// means the most recent attempt did not fail, regardless of whether Premium has been
    /// granted.
    @Test
    func start_clearsLastAttemptFailedOnGenericSyncEvenWithoutPremium() async throws {
        stateService.activeAccount = .fixture()
        stateService.doesActiveAccountHavePremiumResult = false

        await subject.start()
        // Wait for the subscription's baseline snapshot before sending a "new" value below —
        // `start()` reads `getLastSyncTime()` exactly once, before subscribing to the publisher.
        // Without this, the publisher's `CurrentValueSubject` backing could coalesce an
        // immediate send with the not-yet-taken snapshot, making it ambiguous whether the send
        // counts as a change (both nested `Task`s run on the cooperative pool, so a fixed
        // number of `Task.yield()` calls from this `@MainActor` test isn't a reliable proxy).
        try await waitForAsync { stateService.getLastSyncTimeCallCount == 1 }

        stateService.premiumUpgradePendingResult = true
        stateService.premiumUpgradeLastSyncAttemptFailedResult = true
        stateService.lastSyncTimeSubject.send(Date())

        try await waitForAsync { stateService.premiumUpgradeLastSyncAttemptFailedResult == false }
        #expect(stateService.premiumUpgradePendingResult == true)
        #expect(stateService.upgradedToPremiumActionCardVisibleResult == false)
    }

    /// `start()` does not clear a stale `lastAttemptFailed` flag just from subscribing to the
    /// last-sync-time publisher — its `CurrentValueSubject` backing replays the existing cached
    /// value immediately on subscribe, and that replay must not be mistaken for a new sync
    /// completing.
    @Test
    func start_doesNotClearLastAttemptFailedOnInitialSubscriptionReplay() async throws {
        stateService.activeAccount = .fixture()
        stateService.doesActiveAccountHavePremiumResult = true
        stateService.lastSyncTimeSubject.send(Date())
        stateService.premiumUpgradePendingResult = true
        stateService.premiumUpgradeLastSyncAttemptFailedResult = true

        await subject.start()
        try await waitForAsync { stateService.getLastSyncTimeCallCount == 1 }

        #expect(stateService.premiumUpgradeLastSyncAttemptFailedResult == true)
        #expect(stateService.setPremiumUpgradeLastSyncAttemptFailedCallCount == 0)

        // A genuinely new sync, sent only once the initial subscription has settled, still
        // clears the flag as expected.
        stateService.lastSyncTimeSubject.send(Date())

        try await waitForAsync { stateService.premiumUpgradeLastSyncAttemptFailedResult == false }
        #expect(stateService.setPremiumUpgradeLastSyncAttemptFailedCallCount == 1)
    }

    /// `start()` resolves a pending Premium upgrade when a generic sync completes and the
    /// active account has since become Premium, by any means (not just the original checkout
    /// attempt's own subscription).
    @Test
    func start_resolvesPendingUpgradeOnGenericSync() async throws {
        stateService.activeAccount = .fixture()
        stateService.doesActiveAccountHavePremiumResult = false

        await subject.start()
        // See the comment in `start_clearsLastAttemptFailedOnGenericSyncEvenWithoutPremium()`.
        try await waitForAsync { stateService.getLastSyncTimeCallCount == 1 }

        stateService.premiumUpgradePendingResult = true
        stateService.premiumUpgradeLastSyncAttemptFailedResult = true
        stateService.doesActiveAccountHavePremiumResult = true
        stateService.lastSyncTimeSubject.send(Date())

        try await waitForAsync { stateService.premiumUpgradePendingResult == false }
        #expect(stateService.premiumUpgradeLastSyncAttemptFailedResult == false)
        #expect(stateService.upgradedToPremiumActionCardVisibleResult == true)
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
}
