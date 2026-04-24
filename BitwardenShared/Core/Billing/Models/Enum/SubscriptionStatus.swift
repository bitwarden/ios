// MARK: - SubscriptionStatus

/// The raw subscription status values returned by the Stripe API.
///
enum SubscriptionStatus: String, Codable, Equatable, Sendable {
    case active
    case canceled
    case incomplete
    case incompleteExpired = "incomplete_expired"
    case paused
    case pastDue = "past_due"
    case trialing
    case unpaid
}
