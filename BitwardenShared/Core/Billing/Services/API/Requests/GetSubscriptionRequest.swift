import Networking

// MARK: - GetSubscriptionRequest

/// A networking request to get the user's subscription details.
///
struct GetSubscriptionRequest: Request {
    typealias Response = BitwardenSubscriptionResponseModel

    // MARK: Properties

    /// The HTTP method for this request.
    var method: HTTPMethod { .get }

    /// The URL path for this request.
    var path: String { "/account/billing/vnext/subscription" }
}
