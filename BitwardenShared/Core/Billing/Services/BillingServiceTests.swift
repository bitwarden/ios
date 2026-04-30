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
}
