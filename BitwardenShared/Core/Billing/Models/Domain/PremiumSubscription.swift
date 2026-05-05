import Foundation

// MARK: - PremiumSubscription

/// A domain model representing the user's premium subscription details.
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

    // MARK: Computed Properties

    /// The total amount for the next charge (seats + storage + tax - discount), floored at zero.
    var totalAmount: Decimal {
        max(0, seatsCost + storageCost + estimatedTax - discount)
    }

    // MARK: Initialization

    /// Creates a `PremiumSubscription` from a subscription API response.
    ///
    /// - Parameter response: The API response model.
    ///
    init(response: BitwardenSubscriptionResponseModel) {
        let seats = response.cart.passwordManager?.seats
        let storage = response.cart.passwordManager?.additionalStorage

        let seatsCost = (seats?.cost ?? 0) * Decimal(seats?.quantity ?? 0)
        let storageCost = (storage?.cost ?? 0) * Decimal(storage?.quantity ?? 0)

        let itemTotal = seatsCost + storageCost
        let seatDiscount = Self.discountAmount(seats?.discount, on: seatsCost)
        let storageDiscount = Self.discountAmount(storage?.discount, on: storageCost)
        let cartDiscount = Self.discountAmount(response.cart.discount, on: itemTotal)

        cadence = response.cart.cadence
        cancelAt = response.cancelAt
        canceled = response.canceled
        discount = seatDiscount + storageDiscount + cartDiscount
        estimatedTax = response.cart.estimatedTax
        gracePeriod = response.gracePeriod
        nextCharge = response.nextCharge
        self.seatsCost = seatsCost
        status = PremiumPlanStatus(subscriptionStatus: response.status)
        self.storageCost = storageCost
        suspension = response.suspension
    }

    /// Creates a `PremiumSubscription` with explicit values.
    ///
    init(
        cadence: PlanCadenceType,
        cancelAt: Date?,
        canceled: Date?,
        discount: Decimal,
        estimatedTax: Decimal,
        gracePeriod: Int?,
        nextCharge: Date?,
        seatsCost: Decimal,
        status: PremiumPlanStatus,
        storageCost: Decimal,
        suspension: Date?,
    ) {
        self.cadence = cadence
        self.cancelAt = cancelAt
        self.canceled = canceled
        self.discount = discount
        self.estimatedTax = estimatedTax
        self.gracePeriod = gracePeriod
        self.nextCharge = nextCharge
        self.seatsCost = seatsCost
        self.status = status
        self.storageCost = storageCost
        self.suspension = suspension
    }

    // MARK: Private Methods

    /// Computes the discount amount for a cart item.
    ///
    /// - Parameters:
    ///   - discount: The discount model, if any.
    ///   - cost: The item's total cost before discount.
    /// - Returns: The computed discount amount.
    ///
    private static func discountAmount(_ discount: BitwardenDiscountResponseModel?, on cost: Decimal) -> Decimal {
        guard let discount else { return 0 }
        switch discount.type {
        case .amountOff:
            return discount.value
        case .percentOff:
            return cost * discount.value / 100
        }
    }
}
