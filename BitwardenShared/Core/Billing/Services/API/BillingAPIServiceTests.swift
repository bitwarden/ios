import BitwardenKit
import BitwardenKitMocks
import Foundation
import TestHelpers
import Testing

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - BillingAPIServiceTests

@MainActor
struct BillingAPIServiceTests {
    // MARK: Properties

    var activeAccountStateProvider: MockActiveAccountStateProvider!
    var client: MockHTTPClient!
    var stateService: MockStateService!
    var subject: BillingAPIService!

    // MARK: Initialization

    init() {
        activeAccountStateProvider = MockActiveAccountStateProvider()
        client = MockHTTPClient()
        stateService = MockStateService()
        subject = APIService(
            activeAccountStateProvider: activeAccountStateProvider,
            client: client,
            stateService: stateService,
        )
    }

    // MARK: Tests

    /// `createCheckoutSession()` performs the request with the correct method, path, and body.
    @Test
    func createCheckoutSession() async throws {
        client.result = .httpSuccess(testData: .checkoutSession)

        _ = try await subject.createCheckoutSession()

        let request = try #require(client.requests.last)
        #expect(request.method == .post)
        #expect(request.url.absoluteString == "https://example.com/api/account/billing/vnext/premium/checkout")
        #expect(request.body != nil)

        let body = try #require(request.body)
        let json = try JSONSerialization.jsonObject(with: body) as? [String: Any]
        #expect(json?["platform"] as? String == "ios")
    }

    /// `getPortalUrl()` performs the request with the correct method and path.
    @Test
    func getPortalUrl() async throws {
        client.result = .httpSuccess(testData: .portalUrl)

        _ = try await subject.getPortalUrl()

        let request = try #require(client.requests.last)
        #expect(request.method == .post)
        #expect(request.url.absoluteString == "https://example.com/api/account/billing/vnext/portal-session")
        #expect(request.body == nil)
    }

    /// `getPremiumPlan()` performs the request with the correct method and path.
    @Test
    func getPremiumPlan() async throws {
        client.result = .httpSuccess(testData: .premiumPlanResponse)

        _ = try await subject.getPremiumPlan()

        let request = try #require(client.requests.last)
        #expect(request.method == .get)
        #expect(request.url.absoluteString == "https://example.com/api/plans/premium")
        #expect(request.body == nil)
    }

    /// `getSubscription()` performs the request with the correct method and path.
    @Test
    func getSubscription() async throws {
        client.result = .httpSuccess(testData: .subscriptionResponse)

        _ = try await subject.getSubscription()

        let request = try #require(client.requests.last)
        #expect(request.method == .get)
        #expect(request.url.absoluteString == "https://example.com/api/account/billing/vnext/subscription")
        #expect(request.body == nil)
    }
}
