import Foundation
import Networking

// MARK: - BitwardenSubscriptionResponseModel

/// API response model for the user's subscription details.
///
struct BitwardenSubscriptionResponseModel: JSONResponse, Equatable, Sendable {
    // MARK: Properties

    /// If the subscription is pending cancellation, the date at which the
    /// subscription will be canceled.
    let cancelAt: Date?

    /// The date the subscription was canceled.
    let canceled: Date?

    /// The subscription's cart, including line items, any discounts, and estimated tax.
    let cart: SubscriptionCartResponseModel

    /// The number of days after the subscription goes past due the subscriber has to resolve their
    /// open invoices before the subscription is suspended.
    let gracePeriod: Int?

    /// The date of the next charge for the subscription.
    let nextCharge: Date?

    /// The status of the subscription.
    let status: SubscriptionStatus

    /// The amount of storage available and used for the subscription.
    let storage: SubscriptionStorageResponseModel?

    /// The date the subscription will be or was suspended due to lack of payment.
    let suspension: Date?
}

// MARK: - SubscriptionCartResponseModel

/// API response model for a subscription's cart.
///
struct SubscriptionCartResponseModel: JSONResponse, Equatable, Sendable {
    // MARK: Properties

    /// The billing cadence (e.g. annually, monthly).
    let cadence: PlanCadenceType

    /// Any discount applied to the cart.
    let discount: BitwardenDiscountResponseModel?

    /// The estimated tax amount.
    let estimatedTax: Decimal

    /// The Password Manager product line items.
    let passwordManager: PasswordManagerCartItemsResponseModel?
}

// MARK: - PasswordManagerCartItemsResponseModel

/// API response model for Password Manager line items within the cart.
///
struct PasswordManagerCartItemsResponseModel: JSONResponse, Equatable, Sendable {
    // MARK: Properties

    /// The additional storage line item details.
    let additionalStorage: CartItemResponseModel?

    /// The seat line item details.
    let seats: CartItemResponseModel
}

// MARK: - CartItemResponseModel

/// API response model for an individual cart item.
///
struct CartItemResponseModel: JSONResponse, Equatable, Sendable {
    // MARK: Properties

    /// The cost for this cart item.
    let cost: Decimal

    /// Any discount applied to this cart item.
    let discount: BitwardenDiscountResponseModel?

    /// The quantity of this cart item.
    let quantity: Int

    /// The translation key for the cart item's display name.
    let translationKey: String
}

// MARK: - BitwardenDiscountResponseModel

/// API response model for a discount applied to a cart or cart item.
///
struct BitwardenDiscountResponseModel: JSONResponse, Equatable, Sendable {
    // MARK: Properties

    /// The type of discount.
    let type: BitwardenDiscountType

    /// The discount value.
    let value: Decimal
}

// MARK: - SubscriptionStorageResponseModel

/// API response model for a subscription's storage usage.
///
struct SubscriptionStorageResponseModel: JSONResponse, Equatable, Sendable {
    // MARK: Properties

    /// The available storage in GB.
    let available: Double

    /// A human-readable representation of the used storage.
    let readableUsed: String

    /// The used storage in bytes.
    let used: Double
}
