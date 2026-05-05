import Foundation

// MARK: - SubscriptionStatus

/// The raw subscription status values returned by the Stripe API.
///
enum SubscriptionStatus: String, Codable, Equatable, Sendable {
    /// The subscription is active.
    case active

    /// The subscription has been canceled.
    case canceled

    /// The subscription is incomplete.
    case incomplete

    /// The subscription is incomplete and expired.
    case incompleteExpired = "incomplete_expired"

    /// The subscription is paused.
    case paused

    /// The subscription is past due.
    case pastDue = "past_due"

    /// The subscription is in a trial period.
    case trialing

    /// An unknown status not yet supported by the app.
    case unknown

    /// The subscription is unpaid.
    case unpaid

    /// Decodes a `SubscriptionStatus` from the API, defaulting to `.unknown` for unrecognized values.
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = SubscriptionStatus(rawValue: rawValue) ?? .unknown
    }
}
