import Networking

// MARK: - GetSubscriptionRequestError

/// Errors thrown from validating a `GetSubscriptionRequest` response.
///
enum GetSubscriptionRequestError: Error {
    /// The user has no subscription (free plan).
    case noSubscription
}

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

    // MARK: Validation

    func validate(_ response: HTTPResponse) throws {
        if response.statusCode == 404 {
            throw GetSubscriptionRequestError.noSubscription
        }
    }
}
