import Foundation

@testable import BitwardenShared

extension PremiumSubscription {
    static func fixture(
        cadence: PlanCadenceType = .annually,
        cancelAt: Date? = nil,
        canceled: Date? = nil,
        discount: Decimal = 0,
        estimatedTax: Decimal = 0,
        gracePeriod: Int? = nil,
        nextCharge: Date? = nil,
        seatsCost: Decimal = 19.8,
        status: PremiumPlanStatus = .active,
        storageCost: Decimal = 0,
        suspension: Date? = nil,
    ) -> PremiumSubscription {
        PremiumSubscription(
            cadence: cadence,
            cancelAt: cancelAt,
            canceled: canceled,
            discount: discount,
            estimatedTax: estimatedTax,
            gracePeriod: gracePeriod,
            nextCharge: nextCharge,
            seatsCost: seatsCost,
            status: status,
            storageCost: storageCost,
            suspension: suspension,
        )
    }
}
