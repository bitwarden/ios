// MARK: - BillingAPIService

/// A protocol for an API service used to make billing requests.
///
protocol BillingAPIService { // sourcery: AutoMockable
    /// Creates a checkout session for premium upgrade.
    ///
    /// - Returns: A `CheckoutSessionResponseModel` containing the checkout URL.
    ///
    func createCheckoutSession() async throws -> CheckoutSessionResponseModel

    /// Gets the premium subscription plan.
    ///
    /// - Returns: A `PremiumPlanResponseModel` containing the premium plan details.
    ///
    func getPremiumPlan() async throws -> PremiumPlanResponseModel

    /// Creates a customer portal session for managing the premium subscription.
    ///
    /// - Returns: A `PortalUrlResponseModel` containing the portal URL.
    ///
    func getPortalUrl() async throws -> PortalUrlResponseModel
}

// MARK: - APIService Extension

extension APIService: BillingAPIService {
    /// The platform identifier for iOS.
    private static let platform = "ios"

    func createCheckoutSession() async throws -> CheckoutSessionResponseModel {
        try await apiService.send(
            CreateCheckoutSessionRequest(
                requestModel: CheckoutSessionRequestModel(platform: Self.platform),
            ),
        )
    }

    func getPremiumPlan() async throws -> PremiumPlanResponseModel {
        try await apiService.send(GetPremiumPlanRequest())
    }

    func getPortalUrl() async throws -> PortalUrlResponseModel {
        try await apiService.send(GetPortalUrlRequest())
    }
}
