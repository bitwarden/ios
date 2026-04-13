import Foundation
import Networking

// MARK: - PremiumPlanResponseModel

/// API response model for the premium subscription plan.
///
struct PremiumPlanResponseModel: JSONResponse, Equatable, Sendable {
    // MARK: Properties

    /// Whether the plan is available for purchase.
    let available: Bool

    /// The legacy year for this plan.
    let legacyYear: Int?

    /// The name of the plan.
    let name: String

    /// The seat pricing details.
    let seat: PlanPricingResponseModel

    /// The storage pricing details.
    let storage: PlanPricingResponseModel
}

// MARK: - PlanPricingResponseModel

/// API response model for a plan pricing item (seat or storage).
///
struct PlanPricingResponseModel: JSONResponse, Equatable, Sendable {
    // MARK: Properties

    /// The price for this item.
    let price: Decimal

    /// The number of units provided in the base plan.
    let provided: Int

    /// The Stripe price ID.
    let stripePriceId: String
}
