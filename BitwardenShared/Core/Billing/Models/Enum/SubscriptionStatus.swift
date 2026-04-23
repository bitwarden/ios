import Foundation

// MARK: - SubscriptionStatus

/// The status of a subscription as returned by the API.
///
enum SubscriptionStatus: String, Codable, Equatable, Sendable {
    /// The subscription is active.
    case active

    /// The subscription has been canceled.
    case canceled

    /// The subscription is past due.
    case pastDue = "past_due"

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
