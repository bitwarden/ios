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
}
