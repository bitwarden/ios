import Foundation
import Networking

// MARK: - SecretsManagerPlanFeaturesResponseModel

/// API response model for Secrets Manager plan features.
///
struct SecretsManagerPlanFeaturesResponseModel: JSONResponse, Equatable, Sendable {
    // MARK: Properties

    // Seats

    /// The Stripe seat plan ID.
    let stripeSeatPlanId: String?

    /// The price per seat.
    let seatPrice: Decimal

    /// The base number of seats included.
    let baseSeats: Int

    /// The maximum number of additional seats.
    let maxAdditionalSeats: Int?

    /// The maximum number of seats.
    let maxSeats: Int?

    /// Whether the plan has an additional seats option.
    let hasAdditionalSeatsOption: Bool

    // Service Accounts

    /// The Stripe service account plan ID.
    let stripeServiceAccountPlanId: String?

    /// The price per service account.
    let serviceAccountPrice: Decimal

    /// The base number of service accounts included.
    let baseServiceAccount: Int?

    /// The maximum number of additional service accounts.
    let maxAdditionalServiceAccounts: Int?

    /// The maximum number of service accounts.
    let maxServiceAccounts: Int?

    /// Whether the plan has an additional service accounts option.
    let hasAdditionalServiceAccountOption: Bool

    /// The maximum number of projects.
    let maxProjects: Int?
}
