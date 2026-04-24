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
    var errorReporter: MockErrorReporter!
    var stateService: MockStateService!
    var syncService: MockSyncService!
    var subject: DefaultBillingService!

    // MARK: Initialization

    init() {
        billingAPIService = MockBillingAPIService()
        errorReporter = MockErrorReporter()
        stateService = MockStateService()
        syncService = MockSyncService()
        subject = DefaultBillingService(
            billingAPIService: billingAPIService,
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

    /// `getSubscription()` returns the subscription from the API service.
    @Test
    func getSubscription_success() async throws {
        let expectedSubscription = BitwardenSubscriptionResponseModel(
            cancelAt: nil,
            canceled: nil,
            cart: SubscriptionCartResponseModel(
                cadence: .annually,
                discount: nil,
                estimatedTax: 4.55,
                passwordManager: PasswordManagerCartItemsResponseModel(
                    additionalStorage: nil,
                    seats: CartItemResponseModel(
                        cost: 19.8,
                        discount: nil,
                        quantity: 1,
                        translationKey: "premiumMembership",
                    ),
                ),
            ),
            gracePeriod: nil,
            nextCharge: nil,
            status: .active,
            storage: SubscriptionStorageResponseModel(
                available: 5,
                readableUsed: "0 Bytes",
                used: 0,
            ),
            suspension: nil,
        )
        billingAPIService.getSubscriptionReturnValue = expectedSubscription

        let result = try await subject.getSubscription()

        #expect(billingAPIService.getSubscriptionCallsCount == 1)
        #expect(result == expectedSubscription)
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

    /// `premiumStatusChanged()` publishes `.syncing` then `.confirmed` when the user has premium.
    @Test
    func premiumStatusChanged_confirmed() async throws {
        stateService.doesActiveAccountHavePremiumResult = true
        var statuses = [PremiumCheckoutStatus]()
        let cancellable = subject.premiumCheckoutStatusPublisher()
            .sink { statuses.append($0) }

        await subject.premiumStatusChanged()

        #expect(statuses == [.syncing, .confirmed])
        #expect(syncService.didFetchSync)
        _ = cancellable
    }

    /// `premiumStatusChanged()` publishes `.syncing` then `.pending` when the user does not have premium.
    @Test
    func premiumStatusChanged_pending() async throws {
        stateService.doesActiveAccountHavePremiumResult = false
        var statuses = [PremiumCheckoutStatus]()
        let cancellable = subject.premiumCheckoutStatusPublisher()
            .sink { statuses.append($0) }

        await subject.premiumStatusChanged()

        #expect(statuses == [.syncing, .pending])
        #expect(syncService.didFetchSync)
        _ = cancellable
    }

    /// `premiumStatusChanged()` reports the error and publishes `.pending` when sync fails.
    @Test
    func premiumStatusChanged_syncError() async throws {
        syncService.fetchSyncResult = .failure(URLError(.notConnectedToInternet))
        var statuses = [PremiumCheckoutStatus]()
        let cancellable = subject.premiumCheckoutStatusPublisher()
            .sink { statuses.append($0) }

        await subject.premiumStatusChanged()

        #expect(statuses == [.syncing, .pending])
        #expect(errorReporter.errors.first is URLError)
        _ = cancellable
    }

    /// `premiumCheckoutCanceled()` publishes `.canceled`.
    @Test
    func premiumCheckoutCanceled() {
        var statuses = [PremiumCheckoutStatus]()
        let cancellable = subject.premiumCheckoutStatusPublisher()
            .sink { statuses.append($0) }

        subject.premiumCheckoutCanceled()

        #expect(statuses == [.canceled])
        _ = cancellable
    }
}
