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
    var subject: DefaultBillingService!

    // MARK: Initialization

    init() {
        billingAPIService = MockBillingAPIService()
        subject = DefaultBillingService(billingAPIService: billingAPIService)
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

    /// `getSubscription()` maps the API response to a `PremiumSubscription` domain model.
    @Test
    func getSubscription_success() async throws {
        billingAPIService.getSubscriptionReturnValue = BitwardenSubscriptionResponseModel(
            cancelAt: nil,
            canceled: nil,
            cart: SubscriptionCartResponseModel(
                cadence: .annually,
                discount: nil,
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
            status: "active",
            storage: nil,
            suspension: nil,
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

    /// `getSubscription()` maps canceled status correctly.
    @Test
    func getSubscription_canceled() async throws {
        billingAPIService.getSubscriptionReturnValue = BitwardenSubscriptionResponseModel(
            cancelAt: nil,
            canceled: Date(timeIntervalSince1970: 1_800_000_000),
            cart: SubscriptionCartResponseModel(
                cadence: .annually,
                discount: nil,
                estimatedTax: 0,
                passwordManager: nil,
            ),
            gracePeriod: nil,
            nextCharge: nil,
            status: "canceled",
            storage: nil,
            suspension: nil,
        )

        let result = try await subject.getSubscription()

        #expect(result.status == .canceled)
        #expect(result.canceled != nil)
    }

    /// `getSubscription()` maps past_due status correctly.
    @Test
    func getSubscription_pastDue() async throws {
        billingAPIService.getSubscriptionReturnValue = BitwardenSubscriptionResponseModel(
            cancelAt: nil,
            canceled: nil,
            cart: SubscriptionCartResponseModel(
                cadence: .annually,
                discount: nil,
                estimatedTax: 0,
                passwordManager: nil,
            ),
            gracePeriod: 14,
            nextCharge: nil,
            status: "past_due",
            storage: nil,
            suspension: Date(timeIntervalSince1970: 1_803_219_691),
        )

        let result = try await subject.getSubscription()

        #expect(result.status == .pastDue)
        #expect(result.gracePeriod == 14)
        #expect(result.suspension != nil)
    }

    /// `getSubscription()` maps unpaid status to updatePayment.
    @Test
    func getSubscription_unpaid() async throws {
        billingAPIService.getSubscriptionReturnValue = BitwardenSubscriptionResponseModel(
            cancelAt: Date(timeIntervalSince1970: 1_803_219_691),
            canceled: nil,
            cart: SubscriptionCartResponseModel(
                cadence: .annually,
                discount: nil,
                estimatedTax: 0,
                passwordManager: nil,
            ),
            gracePeriod: nil,
            nextCharge: nil,
            status: "unpaid",
            storage: nil,
            suspension: nil,
        )

        let result = try await subject.getSubscription()

        #expect(result.status == .updatePayment)
        #expect(result.cancelAt != nil)
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
}
