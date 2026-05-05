import BitwardenKitMocks
import Combine
import Foundation
import TestHelpers
import Testing

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - BillingServiceTests

@MainActor
struct BillingServiceTests {
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
        configService = MockConfigService()
        configService.featureFlagsBool[.premiumUpgradePath] = true
        environmentService = MockEnvironmentService()
        environmentService.region = .unitedStates
        errorReporter = MockErrorReporter()
        stateService = MockStateService()
        syncService = MockSyncService()
        subject = DefaultBillingService(
            billingAPIService: billingAPIService,
            configService: configService,
            environmentService: environmentService,
            errorReporter: errorReporter,
            stateService: stateService,
            syncService: syncService,
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

    /// `getPremiumPlan()` returns the premium plan from the API service.
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

    /// `getSubscription()` maps unpaid status to updatePayment.
    @Test
    func getSubscription_unpaid() async throws {
        billingAPIService.getSubscriptionReturnValue = .fixture(
            cancelAt: Date(timeIntervalSince1970: 1_803_219_691),
            status: .unpaid,
        )

        let result = try await subject.getSubscription()

        #expect(result.status == .updatePayment)
        #expect(result.cancelAt != nil)
    }

    /// `premiumCheckoutCanceled()` publishes `.canceled` and then resets the publisher value to nil.
    @Test
    func premiumCheckoutCanceled() async throws {
        var statuses = [PremiumCheckoutStatus]()
        let cancellable = subject.premiumCheckoutStatusPublisher()
            .sink { statuses.append($0) }

        subject.premiumCheckoutCanceled()

        try await waitForAsync { !statuses.isEmpty }
        #expect(statuses == [.canceled])

        // After .canceled + nil are sent, a new subscriber should receive nothing (nil is filtered).
        var lateStatuses = [PremiumCheckoutStatus]()
        let lateCancellable = subject.premiumCheckoutStatusPublisher()
            .sink { lateStatuses.append($0) }
        try await waitForAsync { lateStatuses.isEmpty }
    }

    /// A subscriber connecting after `.pending` is emitted receives the pending status immediately
    /// (CurrentValueSubject replays the last value to new subscribers).
    @Test
    func premiumCheckoutStatusPublisher_lateSubscriberReceivesPendingStatus() async throws {
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

    /// `premiumStatusChanged()` returns early without syncing when the user already has premium.
    @Test
    func premiumStatusChanged_alreadyHasPremium() async throws {
        stateService.doesActiveAccountHavePremiumResult = true
        var statuses = [PremiumCheckoutStatus]()
        let cancellable = subject.premiumCheckoutStatusPublisher()
            .sink { statuses.append($0) }

        await subject.premiumStatusChanged()

        #expect(statuses.isEmpty)
        #expect(!syncService.didFetchSync)
    }

    /// `premiumStatusChanged()` publishes `.confirmed` when the user gains premium after sync.
    @Test
    func premiumStatusChanged_confirmed() async throws {
        // Start as non-premium so the guard passes, then switch to premium after sync.
        stateService.doesActiveAccountHavePremiumResult = false
        syncService.fetchSyncHandler = {
            stateService.doesActiveAccountHavePremiumResult = true
        }
        var statuses = [PremiumCheckoutStatus]()
        let cancellable = subject.premiumCheckoutStatusPublisher()
            .sink { statuses.append($0) }

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

        await subject.premiumStatusChanged()
        try await waitForAsync { !earlyStatuses.isEmpty }

        // A subscriber connecting after .confirmed + nil are emitted should receive nothing.
        var lateStatuses = [PremiumCheckoutStatus]()
        let lateCancellable = subject.premiumCheckoutStatusPublisher()
            .sink { lateStatuses.append($0) }
        
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

        await subject.premiumStatusChanged()

        #expect(statuses.isEmpty)
        #expect(!syncService.didFetchSync)
    }

    /// `premiumStatusChanged()` publishes `.pending` when the user does not have premium after sync.
    @Test
    func premiumStatusChanged_pending() async throws {
        stateService.doesActiveAccountHavePremiumResult = false
        var statuses = [PremiumCheckoutStatus]()
        let cancellable = subject.premiumCheckoutStatusPublisher()
            .sink { statuses.append($0) }

        await subject.premiumStatusChanged()

        try await waitForAsync { !statuses.isEmpty }
        #expect(statuses == [.pending])
        #expect(syncService.didFetchSync)
    }

    /// `premiumStatusChanged()` returns early without syncing when the environment is self-hosted.
    @Test
    func premiumStatusChanged_selfHosted() async throws {
        environmentService.region = .selfHosted
        stateService.doesActiveAccountHavePremiumResult = false
        var statuses = [PremiumCheckoutStatus]()
        let cancellable = subject.premiumCheckoutStatusPublisher()
            .sink { statuses.append($0) }

        await subject.premiumStatusChanged()

        #expect(statuses.isEmpty)
        #expect(!syncService.didFetchSync)
    }

    /// `premiumStatusChanged()` reports the error and publishes `.pending` when sync fails.
    @Test
    func premiumStatusChanged_syncError() async throws {
        stateService.doesActiveAccountHavePremiumResult = false
        syncService.fetchSyncResult = .failure(URLError(.notConnectedToInternet))
        var statuses = [PremiumCheckoutStatus]()
        let cancellable = subject.premiumCheckoutStatusPublisher()
            .sink { statuses.append($0) }

        await subject.premiumStatusChanged()

        try await waitForAsync { !statuses.isEmpty }
        #expect(statuses == [.pending])
        #expect(errorReporter.errors.first is URLError)
    }
}
