import Foundation

@testable import BitwardenShared

extension BitwardenSubscriptionResponseModel {
    static func fixture(
        cancelAt: Date? = nil,
        canceled: Date? = nil,
        cart: SubscriptionCartResponseModel = .fixture(),
        gracePeriod: Int? = nil,
        nextCharge: Date? = nil,
        status: SubscriptionStatus = .active,
        storage: SubscriptionStorageResponseModel? = nil,
        suspension: Date? = nil,
    ) -> BitwardenSubscriptionResponseModel {
        BitwardenSubscriptionResponseModel(
            cancelAt: cancelAt,
            canceled: canceled,
            cart: cart,
            gracePeriod: gracePeriod,
            nextCharge: nextCharge,
            status: status,
            storage: storage,
            suspension: suspension,
        )
    }
}

extension SubscriptionCartResponseModel {
    static func fixture(
        cadence: PlanCadenceType = .annually,
        discount: BitwardenDiscountResponseModel? = nil,
        estimatedTax: Decimal = 0,
        passwordManager: PasswordManagerCartItemsResponseModel? = nil,
    ) -> SubscriptionCartResponseModel {
        SubscriptionCartResponseModel(
            cadence: cadence,
            discount: discount,
            estimatedTax: estimatedTax,
            passwordManager: passwordManager,
        )
    }
}
