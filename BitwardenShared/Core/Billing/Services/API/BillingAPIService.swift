// MARK: - BillingAPIService

/// A protocol for an API service used to make billing requests.
///
protocol BillingAPIService { // sourcery: AutoMockable
    /// Creates a checkout session for Premium upgrade.
    ///
    /// - Returns: A `CheckoutSessionResponseModel` containing the checkout URL.
    ///
    func createCheckoutSession() async throws -> CheckoutSessionResponseModel

    /// Creates a customer portal session for managing the Premium subscription.
    ///
    /// - Returns: A `PortalUrlResponseModel` containing the portal URL.
    ///
    func getPortalUrl() async throws -> PortalUrlResponseModel

    /// Gets the Premium subscription plan.
    ///
    /// - Returns: A `PremiumPlanResponseModel` containing the Premium plan details.
    ///
    func getPremiumPlan() async throws -> PremiumPlanResponseModel

    /// Gets the user's subscription details.
    ///
    /// - Returns: A `BitwardenSubscriptionResponseModel` containing the subscription details.
    ///
    func getSubscription() async throws -> BitwardenSubscriptionResponseModel
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

    func getPortalUrl() async throws -> PortalUrlResponseModel {
        try await apiService.send(GetPortalUrlRequest())
    }

    func getPremiumPlan() async throws -> PremiumPlanResponseModel {
        try await apiService.send(GetPremiumPlanRequest())
    }

    func getSubscription() async throws -> BitwardenSubscriptionResponseModel {
        try await apiService.send(GetSubscriptionRequest())
    }
}
