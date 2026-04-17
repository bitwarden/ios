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

    /// Gets the user's subscription details.
    ///
    /// - Returns: A `PremiumSubscription` containing the flattened subscription details.
    ///
    func getSubscription() async throws -> PremiumSubscription
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

    func getSubscription() async throws -> PremiumSubscription {
        let response = try await billingAPIService.getSubscription()
        return mapSubscription(response)
    }

    // MARK: Private Methods

    /// Computes the discount amount for a cart item.
    ///
    /// - Parameters:
    ///   - discount: The discount model, if any.
    ///   - cost: The item's total cost before discount.
    /// - Returns: The computed discount amount.
    ///
    private func discountAmount(_ discount: BitwardenDiscountResponseModel?, on cost: Decimal) -> Decimal {
        guard let discount else { return 0 }
        switch discount.type {
        case .amountOff:
            return discount.value
        case .percentOff:
            return cost * discount.value / 100
        }
    }

    /// Maps a subscription API response to a `PremiumSubscription` domain model.
    ///
    /// - Parameter response: The API response model.
    /// - Returns: A flattened `PremiumSubscription`.
    ///
    private func mapSubscription(_ response: BitwardenSubscriptionResponseModel) -> PremiumSubscription {
        let seats = response.cart.passwordManager?.seats
        let storage = response.cart.passwordManager?.additionalStorage

        let seatsCost = (seats?.cost ?? 0) * Decimal(seats?.quantity ?? 0)
        let storageCost = (storage?.cost ?? 0) * Decimal(storage?.quantity ?? 0)

        let itemTotal = seatsCost + storageCost
        let seatDiscount = discountAmount(seats?.discount, on: seatsCost)
        let storageDiscount = discountAmount(storage?.discount, on: storageCost)
        let cartDiscount = discountAmount(response.cart.discount, on: itemTotal)

        let status: PremiumPlanStatus = switch response.status {
        case "canceled": .canceled
        case "past_due": .pastDue
        case "unpaid": .updatePayment
        default: .active
        }

        return PremiumSubscription(
            cadence: response.cart.cadence,
            cancelAt: response.cancelAt,
            canceled: response.canceled,
            discount: seatDiscount + storageDiscount + cartDiscount,
            estimatedTax: response.cart.estimatedTax,
            gracePeriod: response.gracePeriod,
            nextCharge: response.nextCharge,
            seatsCost: seatsCost,
            status: status,
            storageCost: storageCost,
            suspension: response.suspension,
        )
    }
}
