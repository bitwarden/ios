import Foundation
import Networking

// MARK: - PasswordManagerPlanFeaturesResponseModel

/// API response model for Password Manager plan features.
///
struct PasswordManagerPlanFeaturesResponseModel: JSONResponse, Equatable, Sendable {
    // MARK: Properties

    // Seats

    /// The Stripe plan ID.
    let stripePlanId: String?

    /// The Stripe seat plan ID.
    let stripeSeatPlanId: String?

    /// The Stripe provider portal seat plan ID.
    let stripeProviderPortalSeatPlanId: String?

    /// The Stripe premium access plan ID.
    let stripePremiumAccessPlanId: String?

    /// The base price.
    let basePrice: Decimal

    /// The price per seat.
    let seatPrice: Decimal

    /// The provider portal seat price.
    let providerPortalSeatPrice: Decimal

    /// The premium access option price.
    let premiumAccessOptionPrice: Decimal

    /// The base number of seats included.
    let baseSeats: Int

    /// The maximum number of additional seats.
    let maxAdditionalSeats: Int?

    /// The maximum number of seats.
    let maxSeats: Int?

    /// Whether the plan has a premium access option.
    let hasPremiumAccessOption: Bool

    // Storage

    /// The price per GB for additional storage.
    let additionalStoragePricePerGb: Decimal

    /// The Stripe storage plan ID.
    let stripeStoragePlanId: String?

    /// The base storage in GB.
    let baseStorageGb: Int

    /// Whether the plan has an additional storage option.
    let hasAdditionalStorageOption: Bool

    /// The maximum additional storage.
    let maxAdditionalStorage: Int?

    /// Whether the plan has an additional seats option.
    let hasAdditionalSeatsOption: Bool

    // Feature

    /// The maximum number of collections.
    let maxCollections: Int?
}
