// MARK: - BillingAPIService

/// A protocol for an API service used to make billing requests.
///
protocol BillingAPIService { // sourcery: AutoMockable
    /// Creates a checkout session for premium upgrade.
    ///
    /// - Returns: A `CheckoutSessionResponseModel` containing the checkout URL.
    ///
    func createCheckoutSession() async throws -> CheckoutSessionResponseModel

    /// Gets the list of subscription plans.
    ///
    /// - Returns: A `PlansResponseModel` containing the list of plans.
    ///
    func getPlans() async throws -> PlansResponseModel

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

    func getPlans() async throws -> PlansResponseModel {
        try await apiService.send(GetPlansRequest())
    }

    func getPortalUrl() async throws -> PortalUrlResponseModel {
        try await apiService.send(GetPortalUrlRequest())
    }
}
