import Foundation

// MARK: - PremiumSubscription

/// A domain model representing the user's premium subscription details,.
///
struct PremiumSubscription: Equatable {
    // MARK: Properties

    /// The billing cadence (e.g. annually, monthly).
    let cadence: PlanCadenceType

    /// The date at which the subscription will be canceled, if pending cancellation.
    let cancelAt: Date?

    /// The date the subscription was canceled.
    let canceled: Date?

    /// The total discount amount applied to the subscription.
    let discount: Decimal

    /// The estimated tax amount.
    let estimatedTax: Decimal

    /// The number of days in the grace period after the subscription goes past due.
    let gracePeriod: Int?

    /// The date of the next charge for the subscription.
    let nextCharge: Date?

    /// The total cost for seats (cost × quantity).
    let seatsCost: Decimal

    /// The status of the subscription.
    let status: PremiumPlanStatus

    /// The total cost for additional storage (cost × quantity), or zero if none.
    let storageCost: Decimal

    /// The date the subscription will be suspended due to lack of payment.
    let suspension: Date?
}
