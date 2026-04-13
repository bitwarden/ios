import Foundation

// MARK: - BillingService

/// A protocol for a service used to manage billing operations.
///
protocol BillingService: AnyObject { // sourcery: AutoMockable
    /// Creates a checkout session for premium upgrade and returns the checkout URL.
    ///
    /// - Returns: A validated HTTPS URL for the checkout session.
    /// - Throws: `BillingError.invalidCheckoutUrl` if the URL is invalid or not HTTPS.
    ///
    func createCheckoutSession() async throws -> URL

    /// Gets the premium subscription plan details.
    ///
    /// - Returns: A `PremiumPlanResponseModel` containing the premium plan details.
    ///
    func getPremiumPlan() async throws -> PremiumPlanResponseModel
}

// MARK: - DefaultBillingService

/// The default implementation of `BillingService`.
///
class DefaultBillingService: BillingService {
    // MARK: Properties

    /// The API service used for billing requests.
    private let billingAPIService: BillingAPIService

    // MARK: Initialization

    /// Creates a new `DefaultBillingService`.
    ///
    /// - Parameter billingAPIService: The API service used for billing requests.
    ///
    init(billingAPIService: BillingAPIService) {
        self.billingAPIService = billingAPIService
    }

    // MARK: Methods

    func createCheckoutSession() async throws -> URL {
        let response = try await billingAPIService.createCheckoutSession()
        let url = response.checkoutSessionUrl
        // Ensure the checkout URL uses HTTPS to prevent man-in-the-middle attacks
        // when redirecting users to the payment provider.
        guard url.scheme == "https" else {
            throw BillingError.invalidCheckoutUrl
        }
        return url
    }

    func getPremiumPlan() async throws -> PremiumPlanResponseModel {
        try await billingAPIService.getPremiumPlan()
    }
}
